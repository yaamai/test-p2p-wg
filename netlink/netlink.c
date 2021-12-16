#ifndef NETLINK_H
#define NETLINK_H
#include "netlink.h"

// sendmsg(3, {msg_name={sa_family=AF_NETLINK, nl_pid=0, nl_groups=00000000}, msg_namelen=12, msg_iov=[{iov_base=[{nlmsg_len=32, nlmsg_type=RTM_NEWLINK, nlmsg_flags=NLM_F_REQUEST|NLM_F_ACK, nlmsg_seq=1639343443, nlmsg_pid=0}, {ifi_family=AF_UNSPEC, ifi_type=ARPHRD_NETROM, ifi_index=if_nametoindex("testwg0"), ifi_flags=IFF_UP, ifi_change=0x1}], iov_len=32}], msg_iovlen=1, msg_controllen=0, msg_flags=0}, 0) = 32

int create_ifinfomsg_req(ifinfomsg_req* req, unsigned short type, int ifindex, unsigned int flags) {
  struct rtattr *rta;

  memset(req, 0, sizeof(*req));
  req->nh.nlmsg_len = NLMSG_LENGTH(sizeof(req->msg));
  req->nh.nlmsg_type = type;
  req->nh.nlmsg_flags = NLM_F_REQUEST;

  req->msg.ifi_family = AF_UNSPEC;
  req->msg.ifi_index = ifindex;
  req->msg.ifi_flags = flags;
  req->msg.ifi_change = 0xFFFFFFFF;
/*
  rta = (struct rtattr *)(((char *)req) + NLMSG_ALIGN(req->nh.nlmsg_len));
  rta->rta_type = IFA_LOCAL;
  rta->rta_len = 0;
  req->nh.nlmsg_len = NLMSG_ALIGN(req->nh.nlmsg_len) + RTA_LENGTH(0);
*/
}

int create_ifaddrmsg_req(ifaddrmsg_req* req, unsigned short type, int ifindex, unsigned char family, unsigned char* addr, unsigned char addrlen, unsigned char prefix) {
  struct rtattr *rta;

  memset(req, 0, sizeof(*req));
  req->nh.nlmsg_len = NLMSG_LENGTH(sizeof(req->msg));
  req->nh.nlmsg_type = type;
  req->nh.nlmsg_flags = NLM_F_CREATE | NLM_F_EXCL | NLM_F_REQUEST;

  req->msg.ifa_family = family;
  req->msg.ifa_prefixlen = prefix;
  req->msg.ifa_flags = 0;
  req->msg.ifa_scope = 0;
  req->msg.ifa_index = ifindex;

  rta = (struct rtattr *)(((char *)req) + NLMSG_ALIGN(req->nh.nlmsg_len));
  rta->rta_type = IFA_LOCAL;
  rta->rta_len = RTA_LENGTH(addrlen);
  req->nh.nlmsg_len = NLMSG_ALIGN(req->nh.nlmsg_len) + RTA_LENGTH(addrlen);
  memcpy(RTA_DATA(rta), addr, addrlen);
}

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

int send_request(context* ctx, void* req) {
  int len = -1;
  struct nlmsghdr* nh;

  nh = (struct nlmsghdr*) req;
  nh->nlmsg_seq = ctx->sequence_number;
  nh->nlmsg_flags |= NLM_F_ACK;
  return send(ctx->fd, req, nh->nlmsg_len, 0);
}

int close_socket(context* ctx) {
  return close(ctx->fd);
}

/*
int main() {
  int rc = -1;
  context ctx;
  ifinfomsg_req req;

  rc = prepare_socket(&ctx);
  if (rc < 0) {
    return rc;
  }

  create_ifinfomsg_req(&req, RTM_NEWLINK, 4, IFF_UP);

  rc = send_request(&ctx, &req);
  printf("rc: %d\n", rc);
  rc = recv_response(&ctx);
  printf("rc: %d\n", rc);

  close_socket(&ctx);
}
*/
#endif
