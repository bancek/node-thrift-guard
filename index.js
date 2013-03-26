var thrift = require('thrift');

var guard = function (host, port, cls, ttypes) {
    "use strict";

    var client = null, getClient, proxy, addToProxy, name, methods;

    getClient = function () {
        if (client !== null) {
            return client;
        }

        var connection = thrift.createConnection(host, port);

        connection.on('error', function (err) {
            if (client !== null) {
                client.handleErrors(err);
            }
            client = null;
            console.warn("Thrift error: " + host + ":" + port, err);
        });

        connection.on('close', function (err) {
            if (client !== null) {
                client.handleErrors(err);
            }
            client = null;
            console.warn("Thrift close: " + host + ":" + port, err);
        });

        connection.on('timeout', function (err) {
            if (client !== null) {
                client.handleErrors(err);
            }
            client = null;
            console.warn("Thrift timeout: " + host + ":" + port, err);
        });

        client = thrift.createClient(cls, connection);

        client.handleErrors = function (err) {
            var reqs = client._reqs, id, cb;

            for (id in reqs) {
                if (reqs.hasOwnProperty(id)) {
                    cb = reqs[id];
                    delete reqs[id];
                    cb(err !== null ? err : true);
                }
            }
        };

        return client;
    };

    proxy = {};

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

    return proxy;
};

module.exports = guard;
