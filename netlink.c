#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>

int main() {
  int fd = 0;
  struct sockaddr_nl local;
  int sequence_number = 0;

  fd = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
  if (fd < 0) {
    return -1;
  }

  memset(&local, 0, sizeof(local));
  local.nl_family = AF_NETLINK;
  local.nl_groups = 0;
  if (bind(fd, (struct sockaddr*)&local, sizeof(local)) < 0) {
    return -1;
  }


  int status = 0;
  struct {
    struct nlmsghdr  nh;
    struct ifaddrmsg msg;
    char             attrbuf[512];
  } req;

  struct rtattr *rta;
  unsigned char data[8] = "aaaaaaaa";

  memset(&req, 0, sizeof(req));
  req.nh.nlmsg_len = NLMSG_LENGTH(sizeof(req.msg));
  req.nh.nlmsg_type = RTM_NEWADDR;
  req.nh.nlmsg_flags = NLM_F_CREATE | NLM_F_EXCL | NLM_F_REQUEST;

  req.msg.ifa_family = AF_INET;
  req.msg.ifa_prefixlen = 32;
  req.msg.ifa_flags = 0;
  req.msg.ifa_scope = 0;
  req.msg.ifa_index = 1;

  rta = (struct rtattr *)(((char *) &req) + NLMSG_ALIGN(req.nh.nlmsg_len));
  rta->rta_type = IFA_LOCAL;
  rta->rta_len = RTA_LENGTH(sizeof(data));
  req.nh.nlmsg_len = NLMSG_ALIGN(req.nh.nlmsg_len) + RTA_LENGTH(sizeof(data));
  memcpy(RTA_DATA(rta), &data, sizeof(data));
  status = send(fd, &req, req.nh.nlmsg_len, 0);
  printf("status: %d\n", status);

/*
    addattr_l(&req.n, sizeof(req), IFA_LOCAL, &lcl.data, lcl.bytelen);
    int addattr_l(struct nlmsghdr *n, int maxlen, int type, void *data, int alen)

    int len = RTA_LENGTH(alen);
    struct rtattr *rta;

    if (NLMSG_ALIGN(n->nlmsg_len) + len > maxlen)
        return -1;
    rta = (struct rtattr*)(((char*)n) + NLMSG_ALIGN(n->nlmsg_len));
    rta->rta_type = type;
    rta->rta_len = len;
    memcpy(RTA_DATA(rta), data, alen);
    n->nlmsg_len = NLMSG_ALIGN(n->nlmsg_len) + len;

  {
    struct ifaddrmsg ifa = {
      AF_INET,
      32,
      1,
      0,
      1
    };
    struct nlmsghdr nh = {
      NLMSG_LENGTH(sizeof(struct ifaddrmsg)),
      RTM_NEWADDR,
      NLM_F_CREATE | NLM_F_EXCL | NLM_F_REQUEST
    };
    struct sockaddr_nl sa;
    struct iovec iov = { &nh, nh.nlmsg_len };

    struct msghdr msg = { &sa, sizeof(sa), &iov, 1, NULL, 0, 0 };
    memset(&sa, 0, sizeof(sa));
    sa.nl_family = AF_NETLINK;
    nh.nlmsg_pid = 0;
    nh.nlmsg_seq = ++sequence_number;
    nh.nlmsg_flags |= NLM_F_ACK;

    status = sendmsg(fd, &msg, 0);
    return status;
  }

int rtnl_talk(struct rtnl_handle *rtnl, struct nlmsghdr *n, pid_t peer,
        unsigned groups, struct nlmsghdr *answer)
  {
    struct msghdr msg = { (void*)&nladdr, sizeof(nladdr), &iov, 1, NULL, 0, 0 };

    int status;
    struct nlmsghdr *h;
    struct sockaddr_nl nladdr;
    // Forming the iovector with the netlink packet.
    struct iovec iov = { (void*)n, n->nlmsg_len };
    char buf[8192];
    // Forming the message to be sent.
    struct msghdr msg = { (void*)&nladdr, sizeof(nladdr), &iov, 1, NULL, 0, 0 };
    // Filling up the details of the netlink socket to be contacted in the
    // kernel.
    memset(&nladdr, 0, sizeof(nladdr));
    nladdr.nl_family = AF_NETLINK;
    nladdr.nl_pid = peer;
    nladdr.nl_groups = groups;
    n->nlmsg_seq = ++rtnl->seq;
    if (answer == NULL)
        n->nlmsg_flags |= NLM_F_ACK;
    // Actual sending of the message, status contains success/failure
    status = sendmsg(rtnl->fd, &msg, 0);
    if (status < 0)
        return -1;
  }
*/

  return 0;
}

/*
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <asm/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <malloc.h>
#include <string.h>
#include <iostream>

using namespace std;

struct rtnl_handle
{
    int fd;
    struct sockaddr_nl local;
    struct sockaddr_nl peer;
    __u32 seq;
    __u32 dump;
};

typedef struct
{
    __u8 family;
    __u8 bytelen;
    __s16 bitlen;
    __u32 flags;
    __u32 data[8];
} inet_prefix;

// This uses a non-standard parsing (ie not inet_aton, or inet_pton)
// because of legacy choice to parse 10.8 as 10.8.0.0 not 10.0.0.8

static int get_addr_ipv4(__u8 *ap, const char *cp)
{
    int i;

    for (i = 0; i < 4; i++) {
        unsigned long n;
        char *endp;

        n = strtoul(cp, &endp, 0);
        if (n > 255)
            return -1;      // bogus network value

        if (endp == cp) // no digits
            return -1;

        ap[i] = n;

        if (*endp == '\0')
            break;

        if (i == 3 || *endp != '.')
            return -1;      // extra characters
        cp = endp + 1;
    }

    return 1;
}

// This function is to open the netlink socket as the name suggests.
int netlink_open(struct rtnl_handle* rth)
{
    int addr_len;
    memset(rth, 0, sizeof(rth));

    // Creating the netlink socket of family NETLINK_ROUTE

    rth->fd = socket(AF_NETLINK, SOCK_RAW, NETLINK_ROUTE);
    if (rth->fd < 0)
    {
        perror("cannot open netlink socket");
        return -1;
    }
    memset(&rth->local, 0, sizeof(rth->local));
    rth->local.nl_family = AF_NETLINK;
    rth->local.nl_groups = 0;

    // Binding the netlink socket
    if (bind(rth->fd, (struct sockaddr*)&rth->local, sizeof(rth->local)) < 0)
    {
        perror("cannot bind netlink socket");
        return -1;
    }
    addr_len = sizeof(rth->local);
    if (getsockname(rth->fd, (struct sockaddr*)&rth->local, (socklen_t*) &addr_len) < 0)
    {
        perror("cannot getsockname");
        return -1;
    }
    if (addr_len != sizeof(rth->local))
    {
        fprintf(stderr, "wrong address lenght %d\n", addr_len);
        return -1;
    }
    if (rth->local.nl_family != AF_NETLINK)
    {
        fprintf(stderr, "wrong address family %d\n", rth->local.nl_family);
        return -1;
    }
    rth->seq = time(NULL);
    return 0;
}

// This function does the actual reading and writing to the netlink socket
int rtnl_talk(struct rtnl_handle *rtnl, struct nlmsghdr *n, pid_t peer,
        unsigned groups, struct nlmsghdr *answer)
{
    int status;
    struct nlmsghdr *h;
    struct sockaddr_nl nladdr;
    // Forming the iovector with the netlink packet.
    struct iovec iov = { (void*)n, n->nlmsg_len };
    char buf[8192];
    // Forming the message to be sent.
    struct msghdr msg = { (void*)&nladdr, sizeof(nladdr), &iov, 1, NULL, 0, 0 };
    // Filling up the details of the netlink socket to be contacted in the
    // kernel.
    memset(&nladdr, 0, sizeof(nladdr));
    nladdr.nl_family = AF_NETLINK;
    nladdr.nl_pid = peer;
    nladdr.nl_groups = groups;
    n->nlmsg_seq = ++rtnl->seq;
    if (answer == NULL)
        n->nlmsg_flags |= NLM_F_ACK;
    // Actual sending of the message, status contains success/failure
    status = sendmsg(rtnl->fd, &msg, 0);
    if (status < 0)
        return -1;
}




// This is the utility function for adding the parameters to the packet.
int addattr_l(struct nlmsghdr *n, int maxlen, int type, void *data, int alen)
{
    int len = RTA_LENGTH(alen);
    struct rtattr *rta;

    if (NLMSG_ALIGN(n->nlmsg_len) + len > maxlen)
        return -1;
    rta = (struct rtattr*)(((char*)n) + NLMSG_ALIGN(n->nlmsg_len));
    rta->rta_type = type;
    rta->rta_len = len;
    memcpy(RTA_DATA(rta), data, alen);
    n->nlmsg_len = NLMSG_ALIGN(n->nlmsg_len) + len;
    return 0;
}


int get_addr_1(inet_prefix *addr, const char *name, int family)
{
    memset(addr, 0, sizeof(*addr));

    if (strcmp(name, "default") == 0 ||
            strcmp(name, "all") == 0 ||
            strcmp(name, "any") == 0) {
        if (family == AF_DECnet)
            return -1;
        addr->family = family;
        addr->bytelen = (family == AF_INET6 ? 16 : 4);
        addr->bitlen = -1;
        return 0;
    }

    if (strchr(name, ':')) {
        addr->family = AF_INET6;
        if (family != AF_UNSPEC && family != AF_INET6)
            return -1;
        if (inet_pton(AF_INET6, name, addr->data) <= 0)
            return -1;
        addr->bytelen = 16;
        addr->bitlen = -1;
        return 0;
    }


    addr->family = AF_INET;
    if (family != AF_UNSPEC && family != AF_INET)
        return -1;

    if (get_addr_ipv4((__u8 *)addr->data, name) <= 0)
        return -1;

    addr->bytelen = 4;
    addr->bitlen = -1;
    return 0;
}

int get_prefix(inet_prefix *dst, char *arg, int family)
{
    int err;
    unsigned plen;

    memset(dst, 0, sizeof(*dst));

    if (strcmp(arg, "default") == 0 ||
            strcmp(arg, "any") == 0 ||
            strcmp(arg, "all") == 0) {
        if (family == AF_DECnet)
            return -1;
        dst->family = family;
        dst->bytelen = 0;
        dst->bitlen = 0;
        return 0;
    }

    err = get_addr_1(dst, arg, family);
    if (err == 0) {
        switch(dst->family) {
            case AF_INET6:
                dst->bitlen = 128;
                break;
            case AF_DECnet:
                dst->bitlen = 16;
                break;
            default:
            case AF_INET:
                dst->bitlen = 32;
        }
    }
    return err;
}


int add_IP_Address(char * IP, struct rtnl_handle * rth)
{

    inet_prefix lcl;
    // structure of the netlink packet. 
    struct {
        struct nlmsghdr     n;
        struct ifaddrmsg    ifa;
        char            buf[1024];
    } req;

    memset(&req, 0, sizeof(req));
    req.n.nlmsg_len = NLMSG_LENGTH(sizeof(struct ifaddrmsg));
    req.n.nlmsg_type = RTM_NEWADDR;
    req.n.nlmsg_flags = NLM_F_CREATE | NLM_F_EXCL | NLM_F_REQUEST;


//  req.n.nlmsg_type = RTM_DELADDR;
//  req.n.nlmsg_flags = NLM_F_REQUEST;

    req.ifa.ifa_family = AF_INET ;
    req.ifa.ifa_prefixlen = 32 ;
    req.ifa.ifa_index = 1 ; // get the loopback index
    req.ifa.ifa_scope = 0 ;

    get_prefix(&lcl, IP, req.ifa.ifa_family);
    if (req.ifa.ifa_family == AF_UNSPEC)
        req.ifa.ifa_family = lcl.family;
    addattr_l(&req.n, sizeof(req), IFA_LOCAL, &lcl.data, lcl.bytelen);

    if (rtnl_talk(rth, &req.n, 0, 0, NULL) < 0)
        return -2;
}

int main(int argc, char **argv)
{
    struct rtnl_handle * rth;
    netlink_open(rth);
    char * ip = "1.2.3.4";
    return add_IP_Address(ip,rth);
}
*/
