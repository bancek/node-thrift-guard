var thrift = require('thrift');

var guard = function (host, port, cls, ttypes) {
    "use strict";

    var getClient, proxy, addToProxy, name, methods;

    proxy = {};
    proxy.client = null;

    getClient = function () {
        if (proxy.client) {
            return proxy.client;
        }

        var connection = thrift.createConnection(host, port);

        connection.on('error', function (err) {
            if (proxy.client) {
                proxy.client.handleErrors(err);
            }

            proxy.client = null;

            console.warn("Thrift error: " + host + ":" + port, err);
        });

        connection.on('close', function (err) {
            if (proxy.client) {
                proxy.client.handleErrors(err);
            }

            proxy.client = null;
        });

        connection.on('timeout', function (err) {
            if (proxy.client) {
                proxy.client.handleErrors(err);
            }

            proxy.client = null;

            console.warn("Thrift timeout: " + host + ":" + port, err);
        });

        proxy.client = thrift.createClient(cls, connection);

        proxy.client.connection = connection;

        proxy.client.handleErrors = function (err) {
            var id, reqs, cb;

            reqs = proxy.client._reqs;

            for (id in reqs) {
                if (reqs.hasOwnProperty(id)) {
                    cb = reqs[id];
                    delete reqs[id];
                    cb(err !== null ? err : true);
                }
            }
        };

        return proxy.client;
    };

    addToProxy = function (name, value) {
        if (name.indexOf('send_') === -1 && name.indexOf('recv_') === -1) {
            if (typeof value === 'function') {
                proxy[name] = function () {
                    var cl = getClient();
                    return cl[name].apply(cl, arguments);
                };
            }
        }
    };

    methods = cls.Client.prototype;

    for (name in methods) {
        if (methods.hasOwnProperty(name)) {
            addToProxy(name, methods[name]);
        }
    }

    for (name in ttypes) {
        if (ttypes.hasOwnProperty(name)) {
            proxy[name] = ttypes[name];
        }
    }

    proxy.close = function () {
        if (proxy.client) {
            proxy.client.connection.connection.destroy();
            delete proxy.client;
        }
    };

    return proxy;
};

module.exports = guard;
