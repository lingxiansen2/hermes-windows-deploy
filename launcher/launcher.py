#!/usr/bin/env python3
"""
Hermes Agent Launcher — 通用版 Windows 可视化启动器
=====================================================
功能: 图形化选择 Profile、实时余额显示、一键启动
依赖: Python 3.7+ (tkinter 标准库), DEEPSEEK_API_KEY
"""

import json
import os
import subprocess
import sys
import threading
import time
import tkinter as tk
from tkinter import ttk, messagebox
from urllib.request import Request, urlopen
from urllib.error import URLError
from typing import Optional

# ─── 路径 ────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
PROFILES_DIR = os.path.join(PROJECT_ROOT, "profiles")
VENV_HERMES = os.path.join(PROJECT_ROOT, ".venv", "Scripts", "hermes.exe")

# ─── 颜色 ────────────────────────────────────────────────
C = {
    "bg": "#1e1e1e", "bg2": "#2d2d30", "card": "#252526",
    "fg": "#d4d4d4", "dim": "#888888", "acc": "#4ec9b0",
    "acc2": "#569cd6", "warn": "#ce9178", "green": "#6a9955",
    "red": "#f44747", "border": "#3e3e42",
}

# ─── 余额查询 (自包含，无需外部库) ────────────────────────

def _get_api_key():
    """从 .env 文件读取 DEEPSEEK_API_KEY。"""
    env_file = os.path.join(PROJECT_ROOT, ".env")
    if not os.path.exists(env_file):
        env_file = os.path.join(os.path.dirname(PROJECT_ROOT), ".env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                if line.startswith("DEEPSEEK_API_KEY="):
                    return line.strip().split("=", 1)[1]
    return os.environ.get("DEEPSEEK_API_KEY", "")

def fetch_balance() -> str:
    """查询 DeepSeek 余额，返回格式化字符串。"""
    key = _get_api_key()
    if not key or key.startswith("sk-你的"):
        return "未配置 DEEPSEEK_API_KEY"

    try:
        req = Request(
            "https://api.deepseek.com/user/balance",
            headers={"Accept": "application/json", "Authorization": f"Bearer {key}"},
        )
        data = json.loads(urlopen(req, timeout=10).read())
        infos = data.get("balance_infos", [])
        if not infos:
            return f"DeepSeek | 状态: {'可用' if data.get('is_available') else '不可用'}"
        i = infos[0]
        cur = i.get("currency", "CNY")
        return (
            f"DeepSeek V4 | 总额: {i.get('total_balance','?')} {cur} | "
            f"充值: {i.get('topped_up_balance','?')} {cur} | "
            f"赠送: {i.get('granted_balance','?')} {cur}"
        )
    except Exception as e:
        return f"余额查询失败: {e}"

# ─── Profile 发现 ────────────────────────────────────────

def discover_profiles() -> list[dict]:
    """扫描目录返回可用的 Profile。"""
    profiles = []
    profiles.append({
        "name": "默认工作区",
        "workdir": PROJECT_ROOT,
        "cmd": _make_cmd(PROJECT_ROOT),
        "desc": f"工作目录: {PROJECT_ROOT}",
        "is_default": True,
    })

    if os.path.isdir(PROFILES_DIR):
        for entry in sorted(os.listdir(PROFILES_DIR)):
            pd = os.path.join(PROFILES_DIR, entry)
            if not os.path.isdir(pd):
                continue
            cf = os.path.join(pd, "config.yaml")
            wd = ""
            if os.path.exists(cf):
                try:
                    with open(cf, encoding="utf-8") as f:
                        for line in f:
                            if "cwd:" in line:
                                wd = line.split('"')[1] if '"' in line else line.split(":", 1)[1].strip()
                                break
                except Exception:
                    pass
            profiles.append({
                "name": entry.replace("_", " ").title(),
                "workdir": wd or pd,
                "cmd": _make_cmd(wd or pd),
                "desc": f"工作目录: {wd or pd}",
                "is_default": False,
            })
    return profiles

def _make_cmd(workdir: str) -> list:
    """生成启动 Hermes 的命令。"""
    env = os.environ.copy()
    env["HERMES_HOME"] = os.path.join(PROJECT_ROOT, ".hermes")
    env["TERMINAL_CWD"] = workdir

    # 加载 .env
    env_file = os.path.join(PROJECT_ROOT, ".env")
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                if "=" in line and not line.startswith("#"):
                    k, v = line.strip().split("=", 1)
                    if k not in env:
                        env[k] = v

    hermes = VENV_HERMES if os.path.exists(VENV_HERMES) else "hermes"
    return [hermes, env]

# ─── GUI ─────────────────────────────────────────────────

class HermesLauncher:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Hermes Agent Launcher")
        self.root.geometry("620x480")
        self.root.minsize(480, 380)
        self.root.configure(bg=C["bg"])
        self.root.update_idletasks()
        sw, sh = root.winfo_screenwidth(), root.winfo_screenheight()
        self.root.geometry(f"+{(sw-620)//2}+{(sh-480)//2}")

        self.profiles = []
        self.selected = tk.IntVar(value=0)
        self.balance = tk.StringVar(value="查询余额中...")
        self.status = tk.StringVar(value="就绪")
        self._running = True
        self._balance_tracker = {"text": "查询余额中..."}

        self._build_ui()
        self._refresh()
        self._start_balance()
        self.root.protocol("WM_DELETE_WINDOW", self._close)

    def _build_ui(self):
        # 标题
        tf = tk.Frame(self.root, bg=C["bg"], pady=12)
        tf.pack(fill=tk.X, padx=20)
        tk.Label(tf, text="\U0001F531  Hermes Agent Launcher",
                 font=("Segoe UI", 18, "bold"), fg=C["acc"], bg=C["bg"]).pack(anchor="w")
        tk.Label(tf, text="选择工作区，一键启动 AI 编程助手",
                 font=("Segoe UI", 10), fg=C["dim"], bg=C["bg"]).pack(anchor="w", pady=(2, 0))
        ttk.Separator(self.root, orient="horizontal").pack(fill=tk.X, padx=20, pady=8)

        # Profile 列表
        sf = tk.Frame(self.root, bg=C["bg"])
        sf.pack(fill=tk.BOTH, expand=True, padx=20)
        tk.Label(sf, text="选择工作目录:", font=("Segoe UI", 11, "bold"),
                 fg=C["fg"], bg=C["bg"]).pack(anchor="w", pady=(0, 6))

        lc = tk.Frame(sf, bg=C["card"], highlightbackground=C["border"], highlightthickness=1)
        lc.pack(fill=tk.BOTH, expand=True)
        cv = tk.Canvas(lc, bg=C["card"], highlightthickness=0, height=140)
        sb = tk.Scrollbar(lc, orient="vertical", command=cv.yview)
        self._pf = tk.Frame(cv, bg=C["card"])
        self._pf.bind("<Configure>", lambda e: cv.configure(scrollregion=cv.bbox("all")))
        cv.create_window((0, 0), window=self._pf, anchor="nw")
        cv.configure(yscrollcommand=sb.set)
        cv.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=(8, 0), pady=8)
        sb.pack(side=tk.RIGHT, fill=tk.Y, pady=8)
        cv.bind_all("<MouseWheel>", lambda e: cv.yview_scroll(int(-e.delta/120), "units"))

        # 新建按钮
        bf = tk.Frame(sf, bg=C["bg"], pady=8)
        bf.pack(fill=tk.X)
        tk.Button(bf, text="+  新建 Profile", font=("Segoe UI", 10),
                  bg=C["bg2"], fg=C["acc2"], bd=0, padx=14, pady=6,
                  cursor="hand2", command=self._create).pack(side=tk.LEFT)

        ttk.Separator(self.root, orient="horizontal").pack(fill=tk.X, padx=20, pady=6)

        # 余额
        bf2 = tk.Frame(self.root, bg=C["bg2"], padx=14, pady=10)
        bf2.pack(fill=tk.X, padx=20, pady=(0, 2))
        tk.Label(bf2, text="\U0001F4B0  DeepSeek 余额", font=("Segoe UI", 9, "bold"),
                 fg=C["dim"], bg=C["bg2"]).pack(anchor="w")
        self._bl = tk.Label(bf2, textvariable=self.balance, font=("Consolas", 10),
                             fg=C["green"], bg=C["bg2"], anchor="w")
        self._bl.pack(fill=tk.X, pady=(2, 0))

        # 底部
        bf3 = tk.Frame(self.root, bg=C["bg"], pady=12)
        bf3.pack(fill=tk.X, padx=20)
        tk.Label(bf3, textvariable=self.status, font=("Segoe UI", 9),
                 fg=C["dim"], bg=C["bg"]).pack(side=tk.LEFT)
        self._btn = tk.Button(bf3, text="\U0001F680  启动 Hermes",
                              font=("Segoe UI", 12, "bold"), bg=C["acc"], fg="#1e1e1e",
                              bd=0, padx=30, pady=8, cursor="hand2", command=self._launch)
        self._btn.pack(side=tk.RIGHT)

    def _refresh(self):
        for w in self._pf.winfo_children():
            w.destroy()
        self.profiles = discover_profiles()
        for i, p in enumerate(self.profiles):
            self._add_row(i, p)

    def _add_row(self, i: int, p: dict):
        row = tk.Frame(self._pf, bg=C["card"], pady=6, padx=10)
        row.pack(fill=tk.X)
        tk.Radiobutton(row, variable=self.selected, value=i, bg=C["card"],
                       activebackground=C["card"], selectcolor=C["card"],
                       fg=C["fg"], cursor="hand2").pack(side=tk.LEFT)
        inf = tk.Frame(row, bg=C["card"])
        inf.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(6, 0))
        tk.Label(inf, text=p["name"], font=("Segoe UI", 11, "bold"),
                 fg=C["acc"] if p["is_default"] else C["fg"], bg=C["card"]).pack(anchor="w")
        tk.Label(inf, text=p["desc"], font=("Consolas", 9),
                 fg=C["dim"], bg=C["card"]).pack(anchor="w")
        if p["is_default"]:
            tk.Label(row, text="默认", font=("Segoe UI", 8),
                     fg=C["bg"], bg=C["acc"], padx=8).pack(side=tk.RIGHT, padx=(8, 4))
        if i < len(self.profiles) - 1:
            ttk.Separator(self._pf, orient="horizontal").pack(fill=tk.X, padx=10)

    def _start_balance(self):
        def loop():
            while self._running:
                try:
                    txt = fetch_balance()
                    self.root.after(0, lambda t=txt: self._update_balance(t))
                except Exception:
                    pass
                time.sleep(60)
        threading.Thread(target=loop, daemon=True).start()

    def _update_balance(self, txt: str):
        self.balance.set(txt)
        self._bl.configure(fg=C["red"] if "失败" in txt or "未配置" in txt else
                           C["warn"] if "总额: 0" in txt or "总额: ?" in txt else C["green"])

    def _create(self):
        d = tk.Toplevel(self.root)
        d.title("新建 Profile")
        d.geometry("480x260")
        d.configure(bg=C["bg"])
        d.transient(self.root)
        d.grab_set()
        d.update_idletasks()
        x = self.root.winfo_x() + (self.root.winfo_width() - 480) // 2
        y = self.root.winfo_y() + (self.root.winfo_height() - 260) // 2
        d.geometry(f"+{x}+{y}")

        tk.Label(d, text="新建 Hermes Profile", font=("Segoe UI", 14, "bold"),
                 fg=C["acc"], bg=C["bg"]).pack(pady=(16, 12))

        for label, var_name in [("Profile 名称:", "n"), ("工作目录:", "d")]:
            f = tk.Frame(d, bg=C["bg"])
            f.pack(fill=tk.X, padx=30, pady=4)
            tk.Label(f, text=label, font=("Segoe UI", 10), fg=C["fg"], bg=C["bg"]).pack(anchor="w")
            e = tk.Entry(f, font=("Consolas", 11), bg=C["bg2"], fg=C["fg"],
                         insertbackground=C["fg"], relief="flat")
            e.pack(fill=tk.X, ipady=6, pady=(4, 0))
            if var_name == "n":
                e.insert(0, "my_project")
                name_entry = e
            else:
                dir_entry = e

        def do_create():
            n, wd = name_entry.get().strip(), dir_entry.get().strip()
            if not n or not wd:
                messagebox.showwarning("提示", "请填写名称和目录", parent=d)
                return
            if not os.path.isdir(wd):
                messagebox.showwarning("提示", f"目录不存在:\n{wd}", parent=d)
                return
            fn = n.lower().replace(" ", "_").replace("-", "_")
            pd = os.path.join(PROFILES_DIR, fn)
            if os.path.exists(pd):
                messagebox.showwarning("提示", f"已存在: {fn}", parent=d)
                return
            try:
                os.makedirs(pd, exist_ok=True)
                with open(os.path.join(pd, "config.yaml"), "w", encoding="utf-8") as f:
                    f.write(f"""# Hermes Agent — {n} Profile
models:
  default:
    provider: deepseek
    model: deepseek-v4-pro
    api_key: ${{DEEPSEEK_API_KEY}}
    thinking:
      type: enabled
    reasoning_effort: high
auxiliary:
  default:
    provider: deepseek
    model: deepseek-v4-flash
    api_key: ${{DEEPSEEK_API_KEY}}
    thinking:
      type: disabled
terminal:
  backend: local
  cwd: "{wd}"
  timeout: 180
agent:
  max_turns: 50
  compression_threshold: 80000
log_level: "INFO"
""")
                d.destroy()
                self._refresh()
                self.status.set(f"Profile '{n}' 创建成功")
            except Exception as e:
                messagebox.showerror("错误", str(e), parent=d)

        bf = tk.Frame(d, bg=C["bg"])
        bf.pack(fill=tk.X, padx=30, pady=16)
        tk.Button(bf, text="取消", font=("Segoe UI", 10), bg=C["bg2"], fg=C["fg"],
                  bd=0, padx=20, pady=6, command=d.destroy).pack(side=tk.LEFT)
        tk.Button(bf, text="创建", font=("Segoe UI", 10, "bold"), bg=C["acc"],
                  fg="#1e1e1e", bd=0, padx=20, pady=6, command=do_create).pack(side=tk.RIGHT)

    def _launch(self):
        idx = self.selected.get()
        if idx < 0 or idx >= len(self.profiles):
            return
        p = self.profiles[idx]
        self.status.set(f"启动 {p['name']}...")
        self._btn.configure(state="disabled", text="启动中...")
        self.root.update()
        try:
            hermes, env = p["cmd"]
            subprocess.Popen(
                f'start "Hermes - {p["name"]}" "{hermes}"',
                shell=True, cwd=PROJECT_ROOT, env=env,
            )
            self.status.set(f"{p['name']} 已启动")
        except Exception as e:
            messagebox.showerror("启动失败", str(e))
            self.status.set("失败")
        finally:
            self.root.after(500, lambda: self._btn.configure(
                state="normal", text="\U0001F680  启动 Hermes"))

    def _close(self):
        self._running = False
        self.root.destroy()

def main():
    root = tk.Tk()
    HermesLauncher(root)
    root.mainloop()

if __name__ == "__main__":
    main()
