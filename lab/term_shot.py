#!/usr/bin/env python3
"""
term_shot.py — record a real terminal session and render it to a PNG.

No GUI, no display server: `script(1)` captures the TTY, PIL draws the image.
Every command passed here is genuinely executed; the PNG is the transcript.

Two entry points:

    render_terminal(text, out.png, title="host  -  cmd", cols=104)
        Render already-captured text.

    run_session(container, cmds, ...) -> (raw, clean)
        Run cmds through `docker exec -i <container> script -qec "bash --norc"`
        and return the typescript. Use host_session()/container_session()
        below for the full pattern with prompts and cleaning.

Design notes (these were each learned the hard way):
  * The transcript must come from the surface where the command really runs.
    Recording `docker-compose ...` from inside a container gives
    "command not found" noise that still renders into a plausible PNG.
  * PS1 is injected via `docker exec -e PS1=...` so setup lines never appear.
  * PROMPT_RE preserves the prompt+command lines (that is what a terminal
    looks like) while SETUP_RE deletes the export/unset scaffolding.
"""
import os
import re
import subprocess
import sys

CSI_RE = re.compile(r"\x1b\[[0-9;?]*[ -/]*[@-~]")
OSC_RE = re.compile(r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)")
OTHER_ESC_RE = re.compile(r"\x1b[@-Z\\-_]")


# ------------------------------------------------------------------ ansi ----
def strip_ansi(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = CSI_RE.sub("", text)
    text = OSC_RE.sub("", text)
    return OTHER_ESC_RE.sub("", text)


# -------------------------------------------------------------- cleaning ----
SETUP_RE = re.compile(
    r"^\s*(export\s+(PS1|TERM|LANG|PATH)=|unset\s+BASH_ENV|alias\s+ls=)|"
    r"^\s*Script (started|done) on|^\s*COMMAND=|^\s*exit\s*$|"
    r"^\s*bash-\d[\d.]*[#$]\s*(export|unset|alias|exit)|^\s*(When you exit|make sure to exit)"
)
PROMPT_RE = re.compile(
    r"^(?P<prompt>[\w.\-]+@[\w.\-]+:(?:[^#$]*?)[#$])\s?(?P<cmd>.*)$"
)


def tidy(text):
    """Turn a raw script(1) typescript into a clean terminal view.

    Keeps prompt+command lines (that is what a terminal looks like), drops
    setup scaffolding, the `script` banner, and bare `exit` lines.
    """
    out = []
    for line in text.split("\n"):
        line = line.rstrip()
        if SETUP_RE.match(line):
            continue
        m = PROMPT_RE.match(line)
        if m:
            cmd = m.group("cmd").strip()
            if not cmd or cmd == "exit" or SETUP_RE.match(cmd):
                continue
            out.append("%s %s" % (m.group("prompt"), cmd))
            continue
        if line.startswith("bash-") and "#" in line[:12]:
            continue
        out.append(line)

    # Drop the raw echo block that precedes the first prompt.
    #
    # `script(1)` reading from a pipe (not a real terminal) records stdin twice:
    # once as a bare echo block at the top, then again as prompt+command lines.
    # That first block is an artefact of the recorder, not part of the session,
    # and shipping it makes the image look broken. Match it against the set of
    # commands that actually appear after a prompt and drop it.
    first = next((i for i, l in enumerate(out) if PROMPT_RE.match(l)), None)
    if first is not None and first > 0:
        head = [l.strip() for l in out[:first] if l.strip()]
        tail = {PROMPT_RE.match(l).group("cmd").strip()
                for l in out[first:] if PROMPT_RE.match(l)}
        if head and all(c in tail for c in head):
            out = out[first:]

    res, prev_blank = [], False
    for line in out:
        blank = not line.strip()
        if blank:
            if prev_blank or not res:
                continue
        elif PROMPT_RE.match(line) and not PROMPT_RE.match(line).group("cmd").strip():
            continue
        res.append(line)
        prev_blank = blank
    # no blank line immediately after a prompt+command (CR artefact)
    cleaned = []
    for line in res:
        if not line.strip() and cleaned and PROMPT_RE.match(cleaned[-1]):
            continue
        cleaned.append(line)
    while cleaned and not cleaned[-1].strip():
        cleaned.pop()
    return "\n".join(cleaned)


# ------------------------------------------------------------ recording ----
HOST_STYLE = None  # set by container-style dicts in the caller


def container_session(container, cmds, ps1, timeout=180, cols=104, path=
                      "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"):
    """Record inside a container. `ps1` should name the container
    (e.g. root@attacker-l4) so the image reads as evidence, never the
    container ID hostname."""
    inner = 'script -qec "bash --norc" /tmp/ss_%s.log' % container
    argv = ["docker", "exec", "-i",
            "-e", "PS1=%s" % ps1, "-e", "TERM=xterm-256color",
            "-e", "LANG=C.UTF-8", "-e", "PATH=%s" % path,
            "-e", "COLUMNS=%d" % cols,
            container, "bash", "-c", inner]
    body = ["export PS1='%s'" % ps1, "export TERM=xterm-256color"] + list(cmds) + ["exit"]
    return _pump(argv, body, timeout, cols)


def host_session(cmds, ps1, cwd=".", timeout=180, cols=104):
    """Record on the local host; use for commands that run there."""
    body = ["export PS1='%s'" % ps1, "export TERM=xterm-256color",
            "unset BASH_ENV PROMPT_COMMAND"] + list(cmds) + ["exit"]
    argv = ["bash", "-c", "cd %s && script -qec \"bash --norc\" /tmp/ss_host.log" % cwd]
    return _pump(argv, body, timeout, cols)


def _pump(argv, body, timeout, cols):
    proc = subprocess.Popen(argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT,
                            env={**os.environ, "COLUMNS": str(cols)})
    try:
        out, _ = proc.communicate(("\n".join(body) + "\n").encode(), timeout=timeout)
    except subprocess.TimeoutExpired:
        proc.kill()
        out, _ = proc.communicate()
    return strip_ansi(out.decode("utf-8", "replace"))


def run_remote(container, script, timeout=300):
    """Run a multi-line script in a container WITHOUT nested quoting.

    Nested sh("...\\\"...\\\"") editing silently yields a PNG containing only
    a shell syntax error. Shipping the script through a temp file survives
    every layer.
    """
    name = "/tmp/_ss_%d.sh" % os.getpid()
    subprocess.run(["docker", "exec", "-i", container, "sh", "-c",
                    "cat > %s" % name], input=script.encode(), capture_output=True)
    r = subprocess.run(["docker", "exec", container, "bash", name],
                       capture_output=True, text=True, timeout=timeout)
    subprocess.run(["docker", "exec", container, "rm", "-f", name], capture_output=True)
    return strip_ansi(r.stdout + r.stderr)


# -------------------------------------------------------------- render ----
def render_terminal(text, out_path, title=None, cols=104, font_size=13,
                    max_lines=None, prompt_color=(0, 210, 70)):
    """Draw `text` as a Linux terminal window and save it as PNG."""
    from PIL import Image, ImageDraw, ImageFont

    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", font_size)
    bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", font_size)
    probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    ch_w = probe.textlength("M", font=font)
    line_h = int(font_size * 1.48)
    pad_x, pad_y = 16, 14
    win_pad = 26 if title else 0
    max_w = int(ch_w * cols)
    img_w = int(max_w + pad_x * 2)

    lines = []
    for raw in text.split("\n"):
        cur = ""
        for word in raw.split(" "):
            cand = word if not cur else cur + " " + word
            if probe.textlength(cand, font=font) <= max_w:
                cur = cand
            else:
                if cur:
                    lines.append(cur)
                cur = word
        lines.append(cur)
    if max_lines and len(lines) > max_lines:
        lines = lines[:max_lines] + ["... (output dipotong)"]

    img_h = int(win_pad + pad_y * 2 + len(lines) * line_h)
    img = Image.new("RGB", (img_w, img_h), (44, 44, 48))
    d = ImageDraw.Draw(img)
    d.rectangle([0, win_pad, img_w, img_h], fill=(18, 18, 20))
    if title:
        for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
            cx = 14 + i * 20
            d.ellipse([cx, win_pad // 2 - 6, cx + 12, win_pad // 2 + 6], fill=c)
        d.text((img_w / 2, win_pad / 2), title, font=bold,
               fill=(210, 210, 215), anchor="mm")

    y = win_pad + pad_y
    for line in lines:
        if PROMPT_RE.match(line):
            fill = prompt_color
        elif re.search(r"(not found|No such file|error|Error|Permission denied)", line):
            fill = (255, 120, 120)
        else:
            fill = (225, 225, 230)
        d.text((pad_x, y), line, font=font, fill=fill)
        y += line_h
    img.save(out_path)
    return out_path


def shot(key, text, out_dir, title, caption=""):
    """Write <out_dir>/<key>.png AND <out_dir>/transcripts/<key>.txt.

    Persisting the transcript is mandatory: without a vision model it is the
    only way to audit what the image actually contains.
    """
    os.makedirs(out_dir, exist_ok=True)
    tx_dir = os.path.join(out_dir, "transcripts")
    os.makedirs(tx_dir, exist_ok=True)
    png = render_terminal(text, os.path.join(out_dir, key + ".png"), title=title)
    with open(os.path.join(tx_dir, key + ".txt"), "w", encoding="utf-8") as f:
        f.write(caption + "\n\n" + text if caption else text)
    return png


if __name__ == "__main__":
    print(__doc__)
    sys.exit(0)
