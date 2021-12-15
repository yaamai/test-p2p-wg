##  SPDX-License-Identifier: LGPL-2.1+
##
##  Copyright (C) 2015-2020 Jason A. Donenfeld <Jason@zx2c4.com>. All Rights Reserved.
##
import std/posix

const IFNAMSIZ = 16

type
  wg_key* = array[32, uint8]
  wg_key_b64_string* = array[45, char] or cstring

##  Cross platform __kernel_timespec

type
  timespec64* {.bycopy.} = object
    tv_sec*: int64
    tv_nsec*: int64

  INNER_C_UNION_wireguard_33* {.bycopy, union.} = object
    ip4*: InAddr
    ip6*: In6Addr

  wg_allowedip* {.bycopy.} = object
    family*: uint16
    ano_wireguard_33*: INNER_C_UNION_wireguard_33
    cidr*: uint8
    next_allowedip*: ptr wg_allowedip

  wg_peer_flag* {.size: sizeof(cint).} = enum
    WGPEER_REMOVE_ME = 1,
    WGPEER_REPLACE_ALLOWEDIPS,
    WGPEER_HAS_PUBLIC_KEY,
    WGPEER_HAS_PRESHARED_KEY,
    WGPEER_HAS_PERSISTENT_KEEPALIVE_INTERVAL
  wg_peer_flags = set[wg_peer_flag]


type
  INNER_C_UNION_wireguard_61* {.bycopy, union.} = object
    addr4*: Sockaddr_in
    addr6*: Sockaddr_in6

  wg_peer* {.bycopy.} = object
    flags*: wg_peer_flags
    public_key*: wg_key
    preshared_key*: wg_key
    endpoint*: INNER_C_UNION_wireguard_61
    last_handshake_time*: timespec64
    rx_bytes*: uint64
    tx_bytes*: uint64
    persistent_keepalive_interval*: uint16
    first_allowedip*: ptr wg_allowedip
    last_allowedip*: ptr wg_allowedip
    next_peer*: ptr wg_peer

  wg_device_flag* {.size: sizeof(cint).} = enum
    WGDEVICE_REPLACE_PEERS = 1,
    WGDEVICE_HAS_PRIVATE_KEY,
    WGDEVICE_HAS_PUBLIC_KEY,
    WGDEVICE_HAS_LISTEN_PORT,
    WGDEVICE_HAS_FWMARK
  wg_device_flags = set[wg_device_flag]


type
  wg_device* {.bycopy.} = object
    name*: array[IFNAMSIZ, char]
    ifindex*: uint32
    flags*: wg_device_flags
    public_key*: wg_key
    private_key*: wg_key
    fwmark*: uint32
    listen_port*: uint16
    first_peer*: ptr wg_peer
    last_peer*: ptr wg_peer


{.compile: "wireguard.c".}
proc wg_set_device*(dev: ptr wg_device): cint {.header: "wireguard.h", importc: "wg_set_device"}
proc wg_get_device*(dev: ptr ptr wg_device; device_name: cstring): cint {.header: "wireguard.h", importc: "wg_get_device"}
proc wg_add_device*(device_name: cstring): cint {.header: "wireguard.h", importc: "wg_add_device"}
proc wg_del_device*(device_name: cstring): cint {.header: "wireguard.h", importc: "wg_del_device"}
proc wg_free_device*(dev: ptr wg_device) {.header: "wireguard.h", importc: "wg_free_device"}
##  first\0second\0third\0forth\0last\0\0
proc wg_list_device_names*(): cstring {.header: "wireguard.h", importc: "wg_list_device_names"}
proc wg_key_to_base64*(base64: wg_key_b64_string; key: wg_key) {.header: "wireguard.h", importc: "wg_key_to_base64"}
proc wg_key_from_base64*(key: ptr wg_key; base64: wg_key_b64_string): cint {.header: "wireguard.h", importc: "wg_key_from_base64"}
proc wg_key_is_zero*(key: wg_key): bool {.header: "wireguard.h", importc: "wg_key_is_zero"}
proc wg_generate_public_key*(public_key: wg_key; private_key: wg_key) {.header: "wireguard.h", importc: "wg_generate_public_key"}
proc wg_generate_private_key*(private_key: wg_key) {.header: "wireguard.h", importc: "wg_generate_private_key"}
proc wg_generate_preshared_key*(preshared_key: wg_key) {.header: "wireguard.h", importc: "wg_generate_preshared_key"}
