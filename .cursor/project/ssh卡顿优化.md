# SSH 终端流畅度优化（操作指南）

本文基于 **Tavily** 联网检索与常见运维实践整理，面向「登录慢、交互打字迟滞、多开连接卡顿」等场景。按顺序排查即可。

**检索摘要（来源）**

- 慢登录与 **GSSAPI / DNS**： [Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/5621/how-to-speed-my-too-slow-ssh-login)、[PreshBlog（GSSAPI 挂起）](https://www.preshweb.co.uk/2011/03/slow-ssh-connections-hanging-at-gssapi-auth/)、[Server Fault](https://serverfault.com/questions/371554/ssh-takes-a-long-time-to-connect-on-some-hosts)
- **UseDNS**： [FreeBSD Forums](https://forums.freebsd.org/threads/slow-ssh-login.93863/)、[jrs-s.net 慢 SSH 指南](https://jrs-s.net/2017/07/01/slow-ssh-logins/)
- **连接复用（多路复用）**： [TechRepublic](https://www.techrepublic.com/article/how-to-use-multiplexing-to-speed-up-the-ssh/)、[OpenSSH Wikibooks / Multiplexing](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing)、[geofft 博客](https://ldpreload.com/blog/ssh-control)
- **高延迟下的交互**： [Mosh 官网](https://mosh.org/)、[linux-audit.com](https://linux-audit.com/mosh-ssh-alternative-for-system-administration/)
- **认证与密钥**： [simplified.guide SSH 加速认证](https://www.simplified.guide/ssh/speed-up-authentication)、[DevOps 博文（多项调优）](https://blog.devops.dev/9-ssh-performance-tweaks-every-devops-engineer-should-know-cab1c82fd51c)

---

## 适用说明

| 现象 | 优先看 |
|------|--------|
| 输入密码/密钥后要等很久才出 shell | 下文 **1～3**（客户端、服务端、DNS/GSSAPI） |
| 已登录后每敲一字都慢（高 RTT 网络） | **4 Mosh**；或确认不是本机终端/主题拖慢 |
| 一天内反复 `ssh` 同一台机、git/rsync 也慢 | **5 连接复用** |
| 同一 VPS 上以前快、现在慢 | **6 服务端负载** |

---

## 1. 客户端：关闭 GSSAPI（常能立刻改善「连接阶段」卡顿）

**原因**：客户端若尝试 Kerberos（GSSAPI）认证，在多数家庭/云主机场景用不上，却会增加超时与等待。

在**本机**编辑 `~/.ssh/config`（没有则新建），为对应主机或全局增加：

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
nano ~/.ssh/config   # 或用你喜欢的编辑器
```

写入示例（全局生效可放在文件最前，无 `Host` 则对所有主机生效需谨慎；建议只对常用主机加 `Host 别名`）：

```
Host *
  GSSAPIAuthentication no
```

保存后权限建议：

```bash
chmod 600 ~/.ssh/config
```

**验证**：下次连接时用 `ssh -v user@host` 看是否仍尝试 `gssapi-with-mic`。

---

## 2. 服务端：`UseDNS no`（减轻握手时反向 DNS 等待）

**原因**：OpenSSH 默认可能对客户端 IP 做反向解析；解析慢或失败时，会感觉「连上之前卡住」。

在**服务器**上（需 root 或 sudo）：

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo nano /etc/ssh/sshd_config
```

确保存在或修改为：

```
UseDNS no
```

检查配置并重载（发行版二选一，按实际系统）：

```bash
sudo sshd -t
sudo systemctl reload sshd    # 多数 Linux（服务名可能是 ssh）
# 或
sudo systemctl reload ssh
```

**说明**：若你有强制依赖「只允许某 DNS 名访问」等策略，改前需与运维规范一致。

---

## 3. 服务端：关闭 GSSAPI（与客户端呼应）

在服务器 `sshd_config` 中：

```
GSSAPIAuthentication no
```

同样 `sshd -t` 后 `reload`。与第 1 步一起可消除 [GSSAPI 相关挂起](https://www.preshweb.co.uk/2011/03/slow-ssh-connections-hanging-at-gssapi-auth/)。

---

## 4. 高延迟网络：使用 Mosh（改善「交互打字感」）

**原因**：SSH 交互依赖远端回显；RTT 高时体感明显迟滞。Mosh 通过 UDP 与本地预测回显改善体验（首次仍常经 SSH 启动）。详见 [mosh.org](https://mosh.org/)。

**服务器**（Debian/Ubuntu 示例）：

```bash
sudo apt update && sudo apt install -y mosh
# 防火墙需放行 UDP 60000–61000 左右（以 mosh 文档与发行版为准）
```

**本机**（macOS Homebrew 示例）：

```bash
brew install mosh
```

**使用**：

```bash
mosh user@host
```

---

## 5. 本机：SSH 连接复用（适合频繁连同一主机）

**原因**：多条独立 `ssh`/`scp`/`git` 会重复 TCP + 认证；复用一条主连接可显著减少开销。参见 [OpenSSH Multiplexing](https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Multiplexing)。

在 **`~/.ssh/config`** 中（按主机名替换）：

```
Host myserver
  HostName 你的IP或域名
  User 你的用户名
  ControlMaster auto
  ControlPath ~/.ssh/cm-%r@%h:%p
  ControlPersist 10m
```

首次连接会建立 master；之后同主机会话复用该 socket。

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
```

**注意**：`ControlPath` 目录必须可写；多用户勿共用同一 path。服务器侧 `MaxSessions` 过低可能限制并发，一般默认够用。

---

## 6. 服务端：排除 CPU/内存/磁盘导致的「整台机都卡」

**原因**：与 SSH 无关时，负载高、swap 狂转、磁盘 I/O 满也会让终端响应变差。

在 SSH 会话中：

```bash
top -i 1
# 或
htop
```

关注：`load average`、是否大量进程处于 `D`（不可中断睡眠）、内存是否触顶。必要时扩容或停掉占用进程。

---

## 7. Shell 与终端（本机侧「假卡顿」）

**原因**：Zsh 主题若在提示符里每次执行 `git status`、远程命令等，会放大延迟。

- 临时用极简提示符测试：`PS1='$ '`  
- 或用 `zprof` / 注释主题插件对比  
- 关闭终端透明、大量日志刷屏后再试  

---

## 8. 调试：确认慢在「连接」还是「认证」还是「登录后」

```bash
ssh -vvv user@host 2>&1 | tee /tmp/ssh-debug.log
```

在日志里看停顿发生在 `Authenticating`、`pledge: network` 之后哪一步，再对照上文 1～3 项。

---

## 9. 可选：保持长连接、减少中间设备断开

在 **`~/.ssh/config`**：

```
Host *
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

**原因**：NAT/防火墙空闲断连时，定期保活可减少重连次数（不直接降低单次按键延迟）。

---

## 快速检查清单

1. 本机 `~/.ssh/config`：`GSSAPIAuthentication no`  
2. 服务器 `sshd_config`：`UseDNS no`、`GSSAPIAuthentication no`，`sshd -t` 后 reload  
3. 高 RTT：安装 **Mosh**  
4. 频繁连同一主机：**ControlMaster** 复用  
5. 仍卡：`top`/`htop` 看负载；简化 shell 提示符  

---

*文档生成说明：需求与要点经 Tavily Search API 检索归纳；具体命令以你方操作系统与 OpenSSH 版本为准，修改 `sshd` 前请备份并具备回滚方式。*
