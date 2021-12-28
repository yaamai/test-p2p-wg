sudo ip netns add siteA
sudo ip netns add siteB
sudo ip netns add siteC
sudo ip netns add siteD
sudo ip netns add siteDl
sudo ip netns add siteE
sudo ip netns add siteEl

sudo ip link add vethA type veth peer name veth0
sudo ip link set dev veth0 netns siteA
sudo ip link add vethB type veth peer name veth0
sudo ip link set dev veth0 netns siteB
sudo ip link add vethC type veth peer name veth0
sudo ip link set dev veth0 netns siteC
sudo ip link add vethD type veth peer name veth0
sudo ip link set dev veth0 netns siteD
sudo ip link add vethE type veth peer name veth0
sudo ip link set dev veth0 netns siteE

sudo ip link add inet0 type bridge
sudo ip link set dev inet0 up
sudo ip link set dev vethA master inet0 up
sudo ip link set dev vethB master inet0 up
sudo ip link set dev vethC master inet0 up
sudo ip link set dev vethD master inet0 up
sudo ip link set dev vethE master inet0 up

sudo ip netns exec siteA ip addr add dev veth0 100.0.0.1/24
sudo ip netns exec siteB ip addr add dev veth0 100.0.0.2/24
sudo ip netns exec siteC ip addr add dev veth0 100.0.0.3/24
sudo ip netns exec siteD ip addr add dev veth0 100.0.0.4/24
sudo ip netns exec siteE ip addr add dev veth0 100.0.0.5/24
sudo ip netns exec siteA ip link set dev veth0 up addr 5e:55:de:aa:e7:43
sudo ip netns exec siteB ip link set dev veth0 up addr 5e:55:de:bb:e7:43
sudo ip netns exec siteC ip link set dev veth0 up addr 5e:55:de:cc:e7:43
sudo ip netns exec siteD ip link set dev veth0 up addr 5e:55:de:dd:e7:43
sudo ip netns exec siteE ip link set dev veth0 up addr 5e:55:de:ee:e7:43
sudo ip netns exec siteA ip link set dev lo up
sudo ip netns exec siteB ip link set dev lo up
sudo ip netns exec siteC ip link set dev lo up
sudo ip netns exec siteD ip link set dev lo up
sudo ip netns exec siteE ip link set dev lo up
sudo ip netns exec siteDl ip link set dev lo up
sudo ip netns exec siteEl ip link set dev lo up

sudo ip link add lanD0 type veth peer name veth0
sudo ip link set dev lanD0 netns siteD
sudo ip link set dev veth0 netns siteDl
sudo ip netns exec siteD ip link set dev lanD0 up
sudo ip netns exec siteD ip addr add dev lanD0 192.168.100.254/24
sudo ip netns exec siteDl ip link set dev veth0 up
sudo ip netns exec siteDl ip addr add dev veth0 192.168.100.1/24
sudo ip netns exec siteDl ip route add default via 192.168.100.254
sudo ip netns exec siteD iptables -t nat -I POSTROUTING -o veth0 -j MASQUERADE --random

sudo ip link add lanE0 type veth peer name veth0
sudo ip link set dev lanE0 netns siteE
sudo ip link set dev veth0 netns siteEl
sudo ip netns exec siteE ip link set dev lanE0 up
sudo ip netns exec siteE ip addr add dev lanE0 192.168.200.254/24
sudo ip netns exec siteEl ip link set dev veth0 up
sudo ip netns exec siteEl ip addr add dev veth0 192.168.200.1/24
sudo ip netns exec siteEl ip route add default via 192.168.200.254
sudo ip netns exec siteE iptables -t nat -I POSTROUTING -o veth0 -j MASQUERADE --random
