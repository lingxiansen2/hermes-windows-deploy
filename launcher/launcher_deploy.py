#!/usr/bin/env python3
"""
Hermes Agent Launcher — Deploy Edition
=======================================
路径适配版：自动发现安装位置，兼容开发环境和部署环境。

开发环境：检测 .hermes-win 目录
部署环境：使用 %LOCALAPPDATA%\\hermes 标准路径
"""

import ctypes
import json, os, subprocess, sys, threading, time, tkinter as tk
from tkinter import ttk, messagebox, filedialog
from urllib.request import Request, urlopen

# ─── 路径自动发现 ────────────────────────────────────────
def _get_root():
    """自底向上查找包含 .hermes 或 .hermes-win 的目录"""
    if getattr(sys, 'frozen', False):
        start = os.path.dirname(sys.executable)
    else:
        start = os.path.dirname(os.path.abspath(__file__))
    for _ in range(5):
        for marker in (".hermes-win", ".hermes"):
            if os.path.isdir(os.path.join(start, marker)):
                return start
        parent = os.path.dirname(start)
        if parent == start: break
        start = parent
    # fallback: 当前目录
    return os.getcwd()

def _get_hermes_home():
    """HERMES_HOME: 环境变量 > 自动发现 > 默认 %LOCALAPPDATA%\\hermes"""
    hh = os.environ.get("HERMES_HOME", "")
    if hh and os.path.isdir(hh):
        return hh
    # 开发环境: 同目录 .hermes-win
    dev = os.path.join(ROOT, ".hermes-win")
    if os.path.isdir(dev):
        return dev
    # 开发环境: 同目录 .hermes
    dev2 = os.path.join(ROOT, ".hermes")
    if os.path.isdir(dev2):
        return dev2
    # 部署环境: LOCALAPPDATA\\hermes
    local = os.path.join(os.environ.get("LOCALAPPDATA", os.path.expanduser("~")), "hermes")
    if os.path.isdir(local):
        return local
    os.makedirs(local, exist_ok=True)
    return local

def _get_hermes_cli():
    """查找 hermes CLI 可执行文件"""
    hh = HERMES_HOME
    candidates = [
        os.path.join(hh, "hermes-agent", "venv", "Scripts", "hermes.exe"),
        os.path.join(ROOT, ".venv-hermes-win", "Scripts", "hermes.exe"),
        os.path.join(ROOT, ".venv", "Scripts", "hermes.exe"),
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    # 尝试 which hermes
    import shutil
    found = shutil.which("hermes")
    if found:
        return found
    return "hermes"  # 最后赌一把

ROOT = _get_root()
HERMES_HOME = _get_hermes_home()
HERMES_CLI = _get_hermes_cli()
PROFILES_DIR = os.path.join(HERMES_HOME, "profiles")
SETTINGS_FILE = os.path.join(HERMES_HOME, "launcher_settings.json")

# ─── 配色 ────────────────────────────────────────────────
T = {
    "bg": "#111318", "panel": "#171a21", "card": "#20242d",
    "card_hov": "#252b36", "card_sel": "#263242", "input": "#151922",
    "border": "#303846", "border_soft": "#242a34", "fg": "#d6d9df",
    "fg_dim": "#8d96a5", "accent": "#0ea5e9", "accent_h": "#38bdf8",
    "green": "#37d399", "yellow": "#facc15", "red": "#fb7185",
    "white": "#ffffff", "scroll": "#394252",
}

APP_TITLE = "Hermes"
APP_ID = "Hermes.Agent.WindowsLauncher"

def resource_path(name: str) -> str:
    bases = [
        getattr(sys, "_MEIPASS", ""),
        os.path.dirname(os.path.abspath(__file__)),
        os.path.dirname(sys.executable) if getattr(sys, "frozen", False) else "",
        ROOT,
    ]
    for base in bases:
        if not base:
            continue
        p = os.path.join(base, name)
        if os.path.exists(p):
            return p
    return ""

def configure_app_window(root):
    if sys.platform.startswith("win"):
        try:
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(APP_ID)
        except Exception:
            pass
    icon = resource_path("icon.ico")
    if icon:
        try:
            root.iconbitmap(icon)
        except Exception:
            pass
    try:
        png = resource_path("app_icon.png")
        if png:
            img = tk.PhotoImage(file=png)
            factor = max(1, min(img.width() // 32, img.height() // 32))
            root._title_icon = img.subsample(factor, factor)
            root.iconphoto(True, root._title_icon)
    except Exception:
        pass

def load_app_icon(size=44):
    img = tk.PhotoImage(file=resource_path("app_icon.png"))
    factor = max(1, min(img.width() // size, img.height() // size))
    return img.subsample(factor, factor) if factor > 1 else img

# ─── 设置 ────────────────────────────────────────────────
def load_settings():
    try:
        with open(SETTINGS_FILE) as f: return json.load(f)
    except: return {}

def save_settings(name: str):
    try:
        os.makedirs(os.path.dirname(SETTINGS_FILE), exist_ok=True)
        with open(SETTINGS_FILE, "w") as f: json.dump({"last_profile": name}, f)
    except: pass

# ─── 余额 ────────────────────────────────────────────────
def _get_api_key():
    for p in [os.path.join(HERMES_HOME, ".env"),
              os.path.join(ROOT, ".env")]:
        if os.path.exists(p):
            with open(p) as f:
                for line in f:
                    if line.startswith("DEEPSEEK_API_KEY="):
                        return line.strip().split("=", 1)[1]
    return os.environ.get("DEEPSEEK_API_KEY", "")

def fetch_balance():
    key = _get_api_key()
    if not key or key.startswith("sk-CHANGE") or key.startswith("sk-你的"):
        return {"ok": False, "line": "Key 未配置", "detail": "编辑 %s\\.env" % HERMES_HOME}
    try:
        req = Request("https://api.deepseek.com/user/balance",
                      headers={"Accept": "application/json", "Authorization": f"Bearer {key}"})
        d = json.loads(urlopen(req, timeout=10).read())
        infos = d.get("balance_infos", [])
        if not infos:
            return {"ok": d.get("is_available", False),
                    "line": f"状态: {'可用' if d.get('is_available') else '不可用'}", "detail": ""}
        i = infos[0]; cur = i.get("currency", "CNY")
        return {"ok": d.get("is_available", False),
                "line": f"\u00a5 {float(i.get('total_balance',0)):,.2f} {cur}",
                "detail": f"\u5145\u503c \u00a5{float(i.get('topped_up_balance',0)):,.2f}  |  \u8d60\u9001 \u00a5{float(i.get('granted_balance',0)):,.2f}"}
    except Exception as e:
        return {"ok": False, "line": "\u67e5\u8be2\u5931\u8d25", "detail": str(e)[:60]}

# ─── Profile 发现 ────────────────────────────────────────
def discover_profiles():
    profiles = []
    # 默认工作区
    profiles.append({"name": "\u9ed8\u8ba4\u5de5\u4f5c\u533a",
                     "workdir": ROOT.replace("\\", "/"),
                     "default": True, "icon": "\U0001F3E0",
                     "hermes_home": HERMES_HOME,
                     "config_src": os.path.join(HERMES_HOME, "config.yaml")})

    if os.path.isdir(PROFILES_DIR):
        for entry in sorted(os.listdir(PROFILES_DIR)):
            pd = os.path.join(PROFILES_DIR, entry)
            if not os.path.isdir(pd): continue
            cf = os.path.join(pd, "config.yaml")
            wd = pd; hh = os.path.join(pd, ".hermes")
            if os.path.exists(cf):
                try:
                    with open(cf, encoding="utf-8") as f:
                        for line in f:
                            stripped = line.strip()
                            if stripped.startswith("hermes_home:"):
                                hh = line.split('"')[1] if '"' in line else stripped.split(":", 1)[1].strip()
                                hh = hh.replace("\\", "/")
                            elif stripped.startswith("cwd:"):
                                wd = line.split('"')[1] if '"' in line else stripped.split(":", 1)[1].strip()
                                wd = wd.replace("\\", "/")
                except: pass
            profiles.append({"name": entry.replace("_", " ").title(), "workdir": wd.replace("\\", "/"),
                             "default": False, "icon": "\U0001F4C1",
                             "hermes_home": hh, "config_src": cf if os.path.exists(cf) else ""})
    return profiles

# ─── 启动 ────────────────────────────────────────────────
def launch_hermes(profile: dict):
    hermes = HERMES_CLI
    hh = profile.get("hermes_home", HERMES_HOME)
    wd = profile["workdir"]

    os.makedirs(hh, exist_ok=True)
    # 复制 .env（如果 profile 目录下没有）
    main_env = os.path.join(HERMES_HOME, ".env")
    profile_env = os.path.join(hh, ".env")
    if os.path.exists(main_env) and not os.path.exists(profile_env):
        import shutil
        shutil.copy2(main_env, profile_env)

    import tempfile
    bat_path = os.path.join(tempfile.gettempdir(), f"hermes_launch_{os.getpid()}.bat")
    bat_content = f'''@echo off
chcp 65001 >nul 2>&1
set "HERMES_HOME={hh}"
set "TERMINAL_CWD={wd}"
set "TERMINAL_ENV=local"
set "TERMINAL_TIMEOUT=180"

:: Git Bash PATH（Hermes terminal 必须能找到 bash.exe）
if exist "C:\\Program Files\\Git\\bin\\bash.exe" (
    set "HERMES_GIT_BASH_PATH=C:\\Program Files\\Git\\bin\\bash.exe"
    set "PATH=C:\\Program Files\\Git\\cmd;C:\\Program Files\\Git\\bin;C:\\Program Files\\Git\\usr\\bin;%PATH%"
)

:: 加载 .env 中的 Key
if exist "{hh}\\.env" (
    for /f "usebackq tokens=1,* delims==" %%a in ("{hh}\\.env") do (
        if /i "%%a"=="DEEPSEEK_API_KEY" set "DEEPSEEK_API_KEY=%%b"
        if /i "%%a"=="TAVILY_API_KEY" set "TAVILY_API_KEY=%%b"
    )
)

cd /d "{wd}"
"{hermes}"
'''
    with open(bat_path, "w", encoding="utf-8") as f:
        f.write(bat_content)

    subprocess.Popen(
        f'start "Hermes - {profile["name"]}" cmd /c "{bat_path}"',
        shell=True,
    )

# ─── GUI ─────────────────────────────────────────────────
class Launcher:
    def __init__(self, root):
        self.root = root
        self.root.title(APP_TITLE)
        configure_app_window(self.root)
        self.root.geometry("900x620")
        self.root.minsize(780, 540)
        self.root.configure(bg=T["bg"])
        self.style = ttk.Style()
        try: self.style.theme_use("clam")
        except: pass
        self.style.configure("Vertical.TScrollbar", gripcount=0, background=T["scroll"],
                             darkcolor=T["scroll"], lightcolor=T["scroll"],
                             troughcolor=T["panel"], bordercolor=T["panel"],
                             arrowcolor=T["fg_dim"], relief="flat", width=12)
        self.style.map("Vertical.TScrollbar", background=[("active", T["accent"])])
        self.style.configure("TSeparator", background=T["border_soft"])
        self.root.update_idletasks()
        sw, sh = root.winfo_screenwidth(), root.winfo_screenheight()
        self.root.geometry(f"+{(sw-900)//2}+{(sh-620)//2}")

        self.profiles = []; self._sel = tk.IntVar(value=0)
        self._balance_line = tk.StringVar(value="\u67e5\u8be2\u4e2d...")
        self._balance_detail = tk.StringVar(value="")
        self._running = True; self._cards = []
        try:
            self._brand_icon = load_app_icon(44)
            self._card_icon = load_app_icon(42)
        except Exception:
            self._brand_icon = None; self._card_icon = None

        self._build(); self._refresh(); self._start_balance()
        self.root.protocol("WM_DELETE_WINDOW", self._close)
        self.root.bind("<Up>", lambda e: self._nav(-1))
        self.root.bind("<Down>", lambda e: self._nav(1))
        self.root.bind("<Return>", lambda e: self._launch())
        self.root.bind("<Escape>", lambda e: self.root.destroy())

    def _build(self):
        header = tk.Frame(self.root, bg=T["bg"])
        header.pack(fill=tk.X, padx=28, pady=(22, 14))

        if self._brand_icon:
            mark = tk.Label(header, image=self._brand_icon, bg=T["bg"], width=44, height=44)
            mark.pack(side=tk.LEFT, padx=(0, 14))
        else:
            mark = tk.Canvas(header, width=44, height=44, bg=T["bg"], highlightthickness=0)
            mark.pack(side=tk.LEFT, padx=(0, 14))
            mark.create_rectangle(3, 3, 41, 41, fill=T["accent"], outline="")
            mark.create_text(22, 22, text="H", fill=T["white"], font=("Segoe UI", 20, "bold"))

        title_box = tk.Frame(header, bg=T["bg"])
        title_box.pack(side=tk.LEFT, fill=tk.X, expand=True)
        tk.Label(title_box, text=APP_TITLE, font=("Segoe UI", 22, "bold"),
                 fg=T["white"], bg=T["bg"]).pack(anchor="w")
        tk.Label(title_box, text="Windows \u672c\u5730\u542f\u52a8\u5668  |  %s" % HERMES_CLI,
                 font=("Segoe UI", 10), fg=T["fg_dim"], bg=T["bg"]).pack(anchor="w", pady=(2, 0))

        tk.Label(header, text="\u672c\u5730\u7ec8\u7aef", font=("Segoe UI", 9, "bold"),
                 fg=T["accent_h"], bg=T["panel"], padx=12, pady=6).pack(side=tk.RIGHT)
        ttk.Separator(self.root, orient="horizontal").pack(fill=tk.X, padx=28)

        body = tk.Frame(self.root, bg=T["bg"])
        body.pack(fill=tk.BOTH, expand=True, padx=28, pady=(18, 10))

        left = tk.Frame(body, bg=T["bg"])
        left.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        top_row = tk.Frame(left, bg=T["bg"])
        top_row.pack(fill=tk.X, pady=(0, 10))
        tk.Label(top_row, text="\u5de5\u4f5c\u533a", font=("Segoe UI", 13, "bold"),
                 fg=T["fg"], bg=T["bg"]).pack(side=tk.LEFT)
        tk.Label(top_row, text="\u9009\u62e9\u8981\u542f\u52a8\u7684 Hermes \u73af\u5883",
                 font=("Segoe UI", 9), fg=T["fg_dim"], bg=T["bg"]).pack(side=tk.LEFT, padx=(12, 0), pady=(3, 0))

        list_shell = tk.Frame(left, bg=T["panel"], highlightbackground=T["border_soft"],
                              highlightthickness=1, padx=10, pady=10)
        list_shell.pack(fill=tk.BOTH, expand=True)
        cv = tk.Canvas(list_shell, bg=T["panel"], highlightthickness=0, bd=0)
        sb = ttk.Scrollbar(list_shell, orient="vertical", command=cv.yview, style="Vertical.TScrollbar")
        self._list_frame = tk.Frame(cv, bg=T["panel"])
        self._list_frame.bind("<Configure>", lambda e: cv.configure(scrollregion=cv.bbox("all")))
        self._list_window = cv.create_window((0, 0), window=self._list_frame, anchor="nw")
        cv.configure(yscrollcommand=sb.set)
        cv.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        sb.pack(side=tk.RIGHT, fill=tk.Y, padx=(8, 0))
        cv.bind("<Configure>", lambda e: cv.itemconfigure(self._list_window, width=e.width))
        cv.bind_all("<MouseWheel>", lambda e: cv.yview_scroll(int(-e.delta/120), "units"))

        action_row = tk.Frame(left, bg=T["bg"])
        action_row.pack(fill=tk.X, pady=(12, 0))
        tk.Button(action_row, text="+  \u65b0\u5efa\u5de5\u4f5c\u533a", font=("Segoe UI", 10, "bold"),
                  bg=T["panel"], fg=T["accent_h"], bd=0, activebackground=T["card_hov"],
                  activeforeground=T["white"], padx=18, pady=9, cursor="hand2",
                  command=self._create).pack(side=tk.LEFT)

        right = tk.Frame(body, bg=T["bg"], width=250)
        right.pack(side=tk.RIGHT, fill=tk.Y, padx=(18, 0))
        right.pack_propagate(False)

        bal = tk.Frame(right, bg=T["card"],
                       highlightbackground=T["border_soft"], highlightthickness=1)
        bal.pack(fill=tk.X, padx=18, pady=(0, 12))
        bal_head = tk.Frame(bal, bg=T["card"])
        bal_head.pack(fill=tk.X)
        self._bal_dot_cv = tk.Canvas(bal_head, bg=T["card"], highlightthickness=0, width=12, height=12)
        self._bal_dot = self._bal_dot_cv.create_oval(2, 2, 10, 10, fill=T["fg_dim"], outline="")
        self._bal_dot_cv.pack(side=tk.LEFT, padx=(0, 8), pady=(2, 0))
        tk.Label(bal_head, text="DeepSeek \u4f59\u989d", font=("Segoe UI", 10, "bold"),
                 fg=T["fg"], bg=T["card"]).pack(side=tk.LEFT)
        tk.Label(bal, textvariable=self._balance_line,
                 font=("Segoe UI", 17, "bold"), fg=T["white"], bg=T["card"]).pack(anchor="w", pady=(12, 0))
        tk.Label(bal, textvariable=self._balance_detail,
                 font=("Consolas", 8), fg=T["fg_dim"], bg=T["card"],
                 wraplength=210, justify="left").pack(anchor="w", pady=(4, 0))

        tip = tk.Frame(right, bg=T["card"],
                       highlightbackground=T["border_soft"], highlightthickness=1)
        tip.pack(fill=tk.X, padx=18, pady=16)
        tk.Label(tip, text="\u5feb\u6377\u952e", font=("Segoe UI", 10, "bold"),
                 fg=T["fg"], bg=T["card"]).pack(anchor="w", pady=(0, 8))
        for key, desc in [("\u2191 \u2193", "\u5207\u6362\u5de5\u4f5c\u533a"),
                          ("Enter", "\u542f\u52a8"), ("Esc", "\u9000\u51fa")]:
            r = tk.Frame(tip, bg=T["card"])
            r.pack(fill=tk.X, pady=3)
            tk.Label(r, text=key, font=("Cascadia Mono", 9, "bold"), fg=T["accent_h"],
                     bg=T["input"], width=7, anchor="center", padx=4, pady=2).pack(side=tk.LEFT)
            tk.Label(r, text=desc, font=("Segoe UI", 9), fg=T["fg_dim"],
                     bg=T["card"]).pack(side=tk.LEFT, padx=(10, 0))

        bar = tk.Frame(self.root, bg=T["panel"], highlightbackground=T["border_soft"], highlightthickness=1)
        bar.pack(fill=tk.X, side=tk.BOTTOM)
        bar_inner = tk.Frame(bar, bg=T["panel"])
        bar_inner.pack(fill=tk.X, padx=28, pady=14)
        self._status_lbl = tk.Label(bar_inner, text="\u5c31\u7eea",
                                    font=("Segoe UI", 9), fg=T["fg_dim"], bg=T["panel"])
        self._status_lbl.pack(side=tk.LEFT, pady=(4, 0))
        self._launch_btn = tk.Button(bar_inner, text="\u542f\u52a8 Hermes",
                                     font=("Segoe UI", 12, "bold"), bg=T["accent"],
                                     fg=T["white"], activebackground=T["accent_h"],
                                     activeforeground=T["white"], bd=0, padx=36, pady=11,
                                     cursor="hand2", command=self._launch)
        self._launch_btn.pack(side=tk.RIGHT)

    def _refresh(self):
        for w in self._list_frame.winfo_children(): w.destroy()
        self._cards.clear()
        self.profiles = discover_profiles()
        last = load_settings().get("last_profile", "")
        for i, p in enumerate(self.profiles):
            self._add_card(i, p)
            if p["name"] == last: self._sel.set(i); self._highlight(i)

    def _nav(self, delta):
        n = max(len(self.profiles), 1)
        self._select((self._sel.get() + delta) % n)

    def _select(self, idx):
        self._sel.set(idx); self._highlight(idx)
        save_settings(self.profiles[idx]["name"])

    def _add_card(self, i, p):
        sel = (i == self._sel.get())
        bg = T["card_sel"] if sel else T["card"]
        accent = T["accent_h"] if sel else T["border"]
        card = tk.Frame(self._list_frame, bg=accent, padx=0, pady=0, cursor="hand2")
        card.pack(fill=tk.X, pady=(0, 8))

        inner = tk.Frame(card, bg=bg, padx=14, pady=12)
        inner.pack(fill=tk.X, padx=(4 if sel else 1, 1), pady=1)
        inner.columnconfigure(1, weight=1)

        def click(e=None, idx=i):
            self._select(idx)

        for w in (card, inner):
            w.bind("<Button-1>", click)
            w.bind("<Enter>", lambda e, idx=i: self._hover(idx, True))
            w.bind("<Leave>", lambda e, idx=i: self._hover(idx, False))

        icon_bg = T["accent"] if sel else T["input"]
        if self._card_icon:
            ico = tk.Label(inner, image=self._card_icon, bg=bg, width=42, height=42)
        else:
            ico = tk.Canvas(inner, width=42, height=42, bg=bg, highlightthickness=0)
            ico.create_rectangle(1, 1, 41, 41, fill=icon_bg, outline="")
            ico.create_text(21, 21, text=p["icon"], font=("Segoe UI Emoji", 16), fill=T["white"])
        ico.grid(row=0, column=0, rowspan=2, sticky="w", padx=(0, 14))
        ico.bind("<Button-1>", click)

        fg_c = T["white"] if sel else T["fg"]
        name_lbl = tk.Label(inner, text=p["name"], font=("Segoe UI", 12, "bold"),
                            fg=fg_c, bg=bg, anchor="w")
        name_lbl.grid(row=0, column=1, sticky="ew")
        name_lbl.bind("<Button-1>", click)

        wd = p["workdir"]
        if len(wd) > 78:
            wd = wd[:38] + "..." + wd[-37:]
        path_lbl = tk.Label(inner, text=wd, font=("Cascadia Mono", 8), fg=T["fg_dim"], bg=bg, anchor="w")
        path_lbl.grid(row=1, column=1, sticky="ew", pady=(3, 0))
        path_lbl.bind("<Button-1>", click)

        badge = None
        if p["default"]:
            badge = tk.Label(inner, text="\u9ed8\u8ba4", font=("Segoe UI", 8, "bold"),
                             fg=T["white"], bg=T["accent"], padx=10, pady=3)
            badge.grid(row=0, column=2, rowspan=2, sticky="e", padx=(12, 0))
            badge.bind("<Button-1>", click)

        self._cards.append({"card": card, "inner": inner, "ico": ico, "name_lbl": name_lbl,
                            "path_lbl": path_lbl, "badge": badge, "profile": p})

    def _hover(self, idx, on):
        if idx == self._sel.get() or idx >= len(self._cards): return
        c = self._cards[idx]
        bg = T["card_hov"] if on else T["card"]
        c["inner"].configure(bg=bg)
        c["ico"].configure(bg=bg)
        c["name_lbl"].configure(bg=bg)
        c["path_lbl"].configure(bg=bg)

    def _highlight(self, idx):
        for i, c in enumerate(self._cards):
            sel = (i == idx)
            bg = T["card_sel"] if sel else T["card"]
            c["card"].configure(bg=T["accent_h"] if sel else T["border"])
            c["inner"].configure(bg=bg)
            c["ico"].configure(bg=bg)
            c["name_lbl"].configure(fg=T["white"] if sel else T["fg"], bg=bg)
            c["path_lbl"].configure(bg=bg)
            if isinstance(c["ico"], tk.Canvas):
                c["ico"].delete("all")
                c["ico"].create_rectangle(1, 1, 41, 41, fill=T["accent"] if sel else T["input"], outline="")
                c["ico"].create_text(21, 21, text=c["profile"]["icon"], font=("Segoe UI Emoji", 16), fill=T["white"])

    def _start_balance(self):
        def loop():
            while self._running:
                try:
                    d = fetch_balance()
                    self.root.after(0, lambda d=d: self._update_balance(d))
                except: pass
                time.sleep(60)
        threading.Thread(target=loop, daemon=True).start()

    def _update_balance(self, d):
        self._balance_line.set(d["line"]); self._balance_detail.set(d.get("detail", ""))
        c = T["green"] if d["ok"] else (T["yellow"] if "\u67e5\u8be2" in d["line"] else T["red"])
        self._bal_dot_cv.itemconfig(self._bal_dot, fill=c)

    def _create(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("\u65b0\u5efa\u5de5\u4f5c\u533a")
        dlg.geometry("520x260"); dlg.minsize(420, 220)
        dlg.configure(bg=T["bg"]); dlg.transient(self.root); dlg.grab_set()
        dlg.columnconfigure(0, weight=1); dlg.rowconfigure(0, weight=1)
        dlg.update_idletasks()
        x = self.root.winfo_x() + (self.root.winfo_width() - 520)//2
        y = self.root.winfo_y() + (self.root.winfo_height() - 260)//2
        dlg.geometry(f"+{x}+{y}")

        tk.Label(dlg, text="\u65b0\u5efa Hermes \u5de5\u4f5c\u533a",
                 font=("Segoe UI", 13, "bold"), fg=T["white"], bg=T["bg"]).pack(pady=(18, 14))

        name_entry = dir_entry = None

        def _update_dir_auto(event=None):
            if name_entry and dir_entry and not getattr(dir_entry, '_browsed', False):
                fn = name_entry.get().strip().lower().replace(" ", "_").replace("-", "_")
                if fn:
                    auto_path = os.path.join(PROFILES_DIR, fn)
                    dir_entry.delete(0, tk.END)
                    dir_entry.insert(0, auto_path)

        for lbl_text, var_name in [("\u540d\u79f0", "name"), ("\u5de5\u4f5c\u76ee\u5f55", "dir")]:
            f = tk.Frame(dlg, bg=T["bg"]); f.pack(fill=tk.X, padx=28, pady=4)
            tk.Label(f, text=lbl_text, font=("Segoe UI", 10), fg=T["fg_dim"], bg=T["bg"]).pack(anchor="w")
            if var_name == "dir":
                dr = tk.Frame(f, bg=T["bg"]); dr.pack(fill=tk.X, pady=(3, 0))
                e = tk.Entry(dr, font=("Segoe UI", 11), bg=T["input"], fg=T["fg"],
                             insertbackground=T["fg"], relief="flat", bd=0)
                e.pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=7)
                def browse(ee=e):
                    ee.delete(0, tk.END)
                    path = filedialog.askdirectory(title="\u9009\u62e9\u5de5\u4f5c\u76ee\u5f55")
                    if path:
                        ee.insert(0, path)
                        setattr(ee, '_browsed', True)
                tk.Button(dr, text="\u6d4f\u89c8...", font=("Segoe UI", 9),
                          bg=T["card"], fg=T["fg"], bd=0, padx=12, pady=2,
                          cursor="hand2", command=browse).pack(side=tk.RIGHT, padx=(6, 0))
                dir_entry = e
            else:
                e = tk.Entry(f, font=("Segoe UI", 11), bg=T["input"], fg=T["fg"],
                             insertbackground=T["fg"], relief="flat", bd=0)
                e.pack(fill=tk.X, ipady=7, pady=(3, 0))
                e.bind("<KeyRelease>", _update_dir_auto)
                name_entry = e

        def do_create():
            n = name_entry.get().strip() if name_entry else ""
            wd = dir_entry.get().strip() if dir_entry else ""
            if not n or not wd:
                messagebox.showwarning("\u63d0\u793a", "\u8bf7\u586b\u5199\u540d\u79f0\u548c\u76ee\u5f55", parent=dlg)
                return
            if not os.path.isdir(wd):
                messagebox.showwarning("\u63d0\u793a", "\u76ee\u5f55\u4e0d\u5b58\u5728:\n%s" % wd, parent=dlg)
                return
            fn = n.lower().replace(" ", "_").replace("-", "_")
            pd = os.path.join(PROFILES_DIR, fn)
            if os.path.exists(pd):
                messagebox.showwarning("\u63d0\u793a", "\u5df2\u5b58\u5728: %s" % fn, parent=dlg)
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
                dlg.destroy()
                self._refresh()
                self._status_lbl.configure(text="Profile '%s' \u521b\u5efa\u6210\u529f" % n)
            except Exception as e:
                messagebox.showerror("\u9519\u8bef", str(e), parent=dlg)

        bf = tk.Frame(dlg, bg=T["bg"])
        bf.pack(fill=tk.X, padx=28, pady=16)
        tk.Button(bf, text="\u53d6\u6d88", font=("Segoe UI", 10),
                  bg=T["card"], fg=T["fg"], bd=0, padx=18, pady=6,
                  command=dlg.destroy).pack(side=tk.LEFT)
        tk.Button(bf, text="\u521b\u5efa", font=("Segoe UI", 10, "bold"),
                  bg=T["accent"], fg=T["white"], bd=0, padx=18, pady=6,
                  command=do_create).pack(side=tk.RIGHT)

    def _launch(self):
        idx = self._sel.get()
        if idx < 0 or idx >= len(self.profiles):
            return
        p = self.profiles[idx]
        self._status_lbl.configure(text="\u542f\u52a8 %s..." % p['name'])
        self._launch_btn.configure(state="disabled", text="\u542f\u52a8\u4e2d...")
        self.root.update()
        try:
            launch_hermes(p)
            self._status_lbl.configure(text="%s \u5df2\u542f\u52a8" % p['name'])
        except Exception as e:
            messagebox.showerror("\u542f\u52a8\u5931\u8d25", str(e))
            self._status_lbl.configure(text="\u5931\u8d25")
        finally:
            self.root.after(1000, lambda: self._launch_btn.configure(
                state="normal", text="\u542f\u52a8 Hermes"))

    def _close(self):
        self._running = False
        self.root.destroy()

def main():
    root = tk.Tk()
    Launcher(root)
    root.mainloop()

if __name__ == "__main__":
    main()
