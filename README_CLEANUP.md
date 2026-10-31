Cleanup actions and instructions

I could not delete some binary asset files directly from the editor environment. To safely remove them locally, run the provided PowerShell script.

Run:

```powershell
cd c:\vista
.\scripts\cleanup_assets.ps1
```

The script will prompt for confirmation before deleting:
- `assets\vista-icons\vista1.png`
- `assets\vista-icons\vista_models.gif`
- `assets\vista-icons\vista_loader.gif`

It also removes build folders: `build`, `android\build`, and `android\app\build` if present.

If you'd prefer I create an archive folder instead of deleting, tell me and I will add that script instead.
