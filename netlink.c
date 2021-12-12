#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>

typedef struct {
  struct nlmsghdr  nh;
  struct ifaddrmsg msg;
  char             attrbuf[512];
} ifaddrmsg_req;

int create_ifaddrmsg_req(ifaddrmsg_req* req) {
  struct rtattr *rta;
  unsigned char data[8] = "aaaaaaaa";

  memset(req, 0, sizeof(*req));
  req->nh.nlmsg_len = NLMSG_LENGTH(sizeof(req->msg));
  req->nh.nlmsg_type = RTM_NEWADDR;
  req->nh.nlmsg_flags = NLM_F_CREATE | NLM_F_EXCL | NLM_F_REQUEST;

  req->msg.ifa_family = AF_INET;
  req->msg.ifa_prefixlen = 32;
  req->msg.ifa_flags = 0;
  req->msg.ifa_scope = 0;
  req->msg.ifa_index = 1;

  rta = (struct rtattr *)(((char *)req) + NLMSG_ALIGN(req->nh.nlmsg_len));
  rta->rta_type = IFA_LOCAL;
  rta->rta_len = RTA_LENGTH(sizeof(data));
  req->nh.nlmsg_len = NLMSG_ALIGN(req->nh.nlmsg_len) + RTA_LENGTH(sizeof(data));
  memcpy(RTA_DATA(rta), &data, sizeof(data));
}

typedef struct {
  int fd;
  int sequence_number;
} context;

int prepare_socket(context* ctx) {
  int fd = -1;
  struct sockaddr_nl local;

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

  ctx->fd = fd;
  return 0;
}

int recv_response(context* ctx) {
  // 8192 to avoid message truncation on platforms with page size > 4096
  struct nlmsghdr resp[8192/sizeof(struct nlmsghdr)];
  struct nlmsghdr* nh;
  struct nlmsgerr* err;
  int len = -1;

  len = recv(ctx->fd, &resp, sizeof(resp), 0);
  if (len < 0) {
    return len;
  }

  for (nh = (struct nlmsghdr *) resp; NLMSG_OK (nh, len); nh = NLMSG_NEXT (nh, len)) {
    // printf("resp: %d, nlmsg_type: %d, nlmsg_seq: %d, nlmsg_len: %d, nlmsg_flags: %d\n", len, nh->nlmsg_type, nh->nlmsg_seq, nh->nlmsg_len, nh->nlmsg_flags);
    if (nh->nlmsg_seq != ctx->sequence_number) {
      continue;
    }
    ctx->sequence_number = nh->nlmsg_seq++;

    if (nh->nlmsg_type == NLMSG_DONE) {
      return 0;
    }
    if (nh->nlmsg_type == NLMSG_ERROR) {
      err = (struct nlmsgerr*)(((char*)nh)+NLMSG_HDRLEN);
      return err->error;
    }
  }
  return -1;
}

int send_request(context* ctx, ifaddrmsg_req* req) {
  int len = -1;
  req->nh.nlmsg_seq = ctx->sequence_number;
  req->nh.nlmsg_flags |= NLM_F_ACK;
  return send(ctx->fd, req, req->nh.nlmsg_len, 0);
}

int close_socket(context* ctx) {
  return close(ctx->fd);
}

int main() {
  int rc = -1;
  context ctx;
  ifaddrmsg_req req;

  rc = prepare_socket(&ctx);
  if (rc < 0) {
    return rc;
  }

  create_ifaddrmsg_req(&req);
  rc = send_request(&ctx, &req);
  printf("rc: %d\n", rc);
  rc = recv_response(&ctx);
  printf("rc: %d\n", rc);

  close_socket(&ctx);
}
