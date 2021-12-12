##  SPDX-License-Identifier: LGPL-2.1+
##
##  Copyright (C) 2015-2020 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
##

type
  wg_key* = array[32, uint8_t]
  wg_key_b64_string* = array[((sizeof((wg_key)) + 2) div 3) * 4 + 1, char]

##  Cross platform __kernel_timespec

type
  timespec64* {.bycopy.} = object
    tv_sec*: int64_t
    tv_nsec*: int64_t

  INNER_C_UNION_wireguard_33* {.bycopy, union.} = object
    ip4*: in_addr
    ip6*: in6_addr

  wg_allowedip* {.bycopy.} = object
    family*: uint16_t
    ano_wireguard_33*: INNER_C_UNION_wireguard_33
    cidr*: uint8_t
    next_allowedip*: ptr wg_allowedip

  wg_peer_flags* = enum
    WGPEER_REMOVE_ME = 1U'i64 shl 0, WGPEER_REPLACE_ALLOWEDIPS = 1U'i64 shl 1,
    WGPEER_HAS_PUBLIC_KEY = 1U'i64 shl 2, WGPEER_HAS_PRESHARED_KEY = 1U'i64 shl 3,
    WGPEER_HAS_PERSISTENT_KEEPALIVE_INTERVAL = 1U'i64 shl 4


type
  INNER_C_UNION_wireguard_61* {.bycopy, union.} = object
    `addr`*: sockaddr
    addr4*: sockaddr_in
    addr6*: sockaddr_in6

  wg_peer* {.bycopy.} = object
    flags*: wg_peer_flags
    public_key*: wg_key
    preshared_key*: wg_key
    endpoint*: INNER_C_UNION_wireguard_61
    last_handshake_time*: timespec64
    rx_bytes*: uint64_t
    tx_bytes*: uint64_t
    persistent_keepalive_interval*: uint16_t
    first_allowedip*: ptr wg_allowedip
    last_allowedip*: ptr wg_allowedip
    next_peer*: ptr wg_peer

  wg_device_flags* = enum
    WGDEVICE_REPLACE_PEERS = 1U'i64 shl 0, WGDEVICE_HAS_PRIVATE_KEY = 1U'i64 shl 1,
    WGDEVICE_HAS_PUBLIC_KEY = 1U'i64 shl 2, WGDEVICE_HAS_LISTEN_PORT = 1U'i64 shl 3,
    WGDEVICE_HAS_FWMARK = 1U'i64 shl 4


type
  wg_device* {.bycopy.} = object
    name*: array[IFNAMSIZ, char]
    ifindex*: uint32_t
    flags*: wg_device_flags
    public_key*: wg_key
    private_key*: wg_key
    fwmark*: uint32_t
    listen_port*: uint16_t
    first_peer*: ptr wg_peer
    last_peer*: ptr wg_peer


proc wg_set_device*(dev: ptr wg_device): cint
proc wg_get_device*(dev: ptr ptr wg_device; device_name: cstring): cint
proc wg_add_device*(device_name: cstring): cint
proc wg_del_device*(device_name: cstring): cint
proc wg_free_device*(dev: ptr wg_device)
proc wg_list_device_names*(): cstring
##  first\0second\0third\0forth\0last\0\0

proc wg_key_to_base64*(base64: wg_key_b64_string; key: wg_key)
proc wg_key_from_base64*(key: wg_key; base64: wg_key_b64_string): cint
proc wg_key_is_zero*(key: wg_key): bool
proc wg_generate_public_key*(public_key: wg_key; private_key: wg_key)
proc wg_generate_private_key*(private_key: wg_key)
proc wg_generate_preshared_key*(preshared_key: wg_key)