#ifndef NETLINK_H
#define NETLINK_H

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <net/if.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>

typedef struct ifinfomsg_req {
  struct nlmsghdr  nh;
  struct ifinfomsg msg;
  char             attrbuf[512];
} ifinfomsg_req;

typedef struct {
  struct nlmsghdr  nh;
  struct ifaddrmsg msg;
  char             attrbuf[512];
} ifaddrmsg_req;

typedef struct context {
  int fd;
  int sequence_number;
} context;

int create_ifinfomsg_req(ifinfomsg_req* req, unsigned short type, u32 ifindex, unsigned int flags);
int create_ifaddrmsg_req(ifaddrmsg_req* req, unsigned short type, u32 ifindex, unsigned char family, unsigned char* addr, unsigned char addrlen, unsigned char prefix);
int prepare_socket(context* ctx);
int recv_response(context* ctx);
int send_request(context* ctx, void* req);
int close_socket(context* ctx);

#endif
