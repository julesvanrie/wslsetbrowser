# WSL Set Browser
Script to easily set your browser config in WSL.

This sets:
- The `BROWSER` and `GH_BROWSER` environment variables.
- In both `.bashrc` and `.zshrc`.

These are needed by some tools to automatically open your Windows browser, for example:
- `jupyter notebook`
- `gh browse`


## Usage
```bash
bash -c "$(curl -s https://raw.githubusercontent.com/julesvanrie/wslsetbrowser/refs/heads/main/wslsetbrowser.sh)"
```

The script will then detect the installed browsers, and prompt you to choose one. The script will then update `.bashrc` and `.zshrc`.

You can also provide your own Windows path to your browser. The script will convert it to the WSL path.

Previous `BROWSER` and `GH_BROWSER` settings will be removed.

## Supported browsers:
- **Chrome** (installed normally, and in x86)
- **Firefox** (installed normally, in x86, and user install through Microsoft Store)
- **Edge**
- **Brave** (installed normally, and user install through Microsoft Store)
- **Opera**
- **Arc**
- **Zen**

If you have **another browser**, or find any of these browsers in another location, feel free to submit an issue, or a PR.
