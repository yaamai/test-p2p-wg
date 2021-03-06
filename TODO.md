- [ ] implement nat traversal
  - [x] append self public key to communication target peer (pubkey: self.pubkey, allowed-ip: self.ip)
  - [x] get target endpoint and target tunnel ip from target's successor
  - [x] append target peer pubkey to self (pubkey: target.pubkey, endpoint: target.ep, allowed_ip: target.tunnel_ip)
  - [x] add ip route on target peer
    - maybe `/16` route are sufficient
  - [x] hold last connectable peer
- [ ] decouple wireguard device using device name
- [x] expose netlink information at chord kvs
  - [x] interface local address
    - this solved by successor's wireguard endpoint address
- [x] export chord information at chord kvs
- [ ] migrate new wireguard interface
- [ ] refactor config with new wg i/f
- [ ] clarify wireguard device configure/structure
- [ ] propagate http request error correctly
- [ ] use json instead of raw text at chord server response
- [ ] separate state(nat discovered peers?) and config
- [ ] implement netlink replace flags instead of error ignore
- [ ] suppress stabilize logs
- [ ] move json library to json2
- [ ] implement high availability (multiple successor)
- [ ] implement fingers
- [ ] add integration tests
