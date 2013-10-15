struct PingMsg {
  1: string msg
}

struct PongMsg {
  1: string msg
}

service PingService {
  PongMsg ping(1: PingMsg msg)
}
