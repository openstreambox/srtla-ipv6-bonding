# srtla-ipv6-bonding

**VPS-free cellular bandwidth bonding for live video, over IPv6.**

Notes + ready-to-use configs for aggregating several cellular uplinks into one reliable SRT feed using **SRTLA** — with **no public-IPv4 anchor / no VPS**, by going IPv6-direct to a receiver at home.

## The problem & what was verified
For drop-free mobile/IRL streaming you want to *bond* multiple cellular links (carrier diversity + aggregated upload). Two transports were tested on real IPv6:

- **SRT connection bonding (socket groups)** — built into libsrt. **Verified NOT to work over IPv6**: the group-member handshake silently times out (it works over IPv4; plain non-grouped SRT works fine over IPv6). So "VPS-free IPv6 group bonding" is a dead end with stock SRT.
- **SRTLA** (the BELABOX bonding protocol). The original BELABOX `srtla` is IPv4-only (`AF_INET` hardcoded) — which is why it normally needs a public-IPv4 VPS anchor. **But [IRLServer](https://github.com/IRLServer)'s fork is dual-stack**: `irl-srt-server` binds `AF_INET6` with `SRTO_IPV6ONLY=0`, and `srtla_send` is IPv6-aware. **Verified working: SRTLA carries A/V end-to-end over IPv6**, receiver at home, no VPS.

So: **bond your cellular links with SRTLA straight to a home box over IPv6.** This repo is the recipe + configs.

## Architecture
```
[car: encoder ─SRT─> srtla_send  (binds N source IPs = N uplinks)]
        │  SRTLA over IPv6   (each modem = one bonded link)
        ▼  (home router: one inbound UDP-port pinhole)
[home: irl-srt-server  (SRTLA receiver, IPv6 dual-stack)  ─SRT─> MediaMTX / OBS / your server]
```

## Build the stack (Debian/Ubuntu)
Three third-party components, all from IRLServer:

1. **Patched libsrt** — `github.com/irlserver/srt` branch `belabox`. Pin a known-good commit (HEAD has regressed):
   ```sh
   git clone https://github.com/irlserver/srt && cd srt
   git checkout <SRT_COMMIT>   # use the commit pinned in irl-srt-server's Dockerfile
   ./configure && make -j && sudo make install && sudo ldconfig
   # confirm: grep SRTO_SRTLAPATCHES /usr/local/include/srt/srt.h
   ```
2. **Receiver** — `github.com/IRLServer/irl-srt-server`:
   ```sh
   sudo apt install -y libspdlog-dev zlib1g-dev
   git submodule update --init --recursive
   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j
   # -> build/bin/srt_server
   ```
3. **Sender** — `github.com/IRLServer/srtla_send` (Rust):
   ```sh
   cargo build --release   # -> target/release/srtla_send
   ```

## Run
- **Home receiver:** `srt_server -c receiver/sls.conf` (or `receiver/start_receiver.sh`). Listens for SRTLA on `:4002`, republishes SRT on `:4000` (`streamid=play/live/bond`).
- **Car sender:** put one public source IP per uplink in `sender/bind_ips.txt`, set `RECEIVER_IPV6` in `sender/car_send.sh`, run it. Your encoder pushes SRT to `srt://127.0.0.1:7000?streamid=publish/live/bond`.
- **Bridge to MediaMTX/OBS:** pull `srt://RECEIVER:4000?streamid=play/live/bond` into MediaMTX, then read it in OBS. Pulling over **LAN IPv4** is easiest (dodges a cosmetic IPv6-address log bug in the fork); the car→home SRTLA stays IPv6.

## Gotchas found the hard way
- libsrt fork: use the **pinned `SRT_COMMIT`** — belabox HEAD broke `srt_listen`.
- `sls.conf` **must set `backlog`** — without it `srt_listen(fd, 0)` fails with "Bad parameters".
- Stream IDs: publisher `publish/live/<name>`, player `play/live/<name>`. Bring the **publisher up before** the player.
- The fork logs `pton: can't determine IPv4 carryover format` for real-IPv6 peers — cosmetic, but it can stall delivery to an IPv6 *player*; pull the receiver's output over LAN IPv4 to avoid it.

## Status
SRTLA-over-IPv6 transport + the full home-side receive chain are verified end-to-end. True multi-uplink *throughput* aggregation needs 2+ real cellular links to measure — the mechanism is proven; the aggregation gain is hardware-dependent.

## Credit
The heavy lifting is [IRLServer](https://github.com/IRLServer)'s SRT/SRTLA fork. This repo is the IPv6 / VPS-free recipe + configs around it.

## License
MIT — see [LICENSE](LICENSE).
