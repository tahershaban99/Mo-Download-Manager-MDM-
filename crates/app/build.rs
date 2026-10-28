fn main() {
    // "fluent" follows the light/dark switch the app makes at runtime
    // Arabic texts: lang/ar/LC_MESSAGES/swiftget.po (made by lang/make_po.py)
    let config = slint_build::CompilerConfiguration::new()
        .with_style("fluent".into())
        .with_bundled_translations("lang")
        .with_default_translation_context(slint_build::DefaultTranslationContext::None);
    for lang in ["ar", "fr", "es", "de", "pt", "tr", "ru"] {
        println!("cargo:rerun-if-changed=lang/{lang}/LC_MESSAGES/swiftget.po");
    }
    println!("cargo:rerun-if-changed=lang/rs");
    slint_build::compile_with_config("ui/app.slint", config).expect("Slint UI failed to compile");

    // Icon, full version information and a standard manifest for
    // MDM.exe. Antivirus programs trust a program more when it says
    // clearly who made it, what it is and that it runs without admin rights.
    #[cfg(windows)]
    {
        let version = env!("CARGO_PKG_VERSION");
        let mut res = winresource::WindowsResource::new();
        res.set_icon("icon.ico");
        res.set("ProductName", "Mo Download Manager (MDM)");
        res.set("FileDescription", "Mo Download Manager (MDM)");
        res.set("CompanyName", "Mohamed");
        res.set("LegalCopyright", "Copyright (C) 2026 Mohamed");
        res.set("OriginalFilename", "MDM.exe");
        res.set("InternalName", "MDM");
        res.set("ProductVersion", version);
        res.set("FileVersion", version);
        res.set_manifest(
            r#"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity type="win32" name="Mohamed.MDM" version="1.0.0.0" processorArchitecture="*"/>
  <description>Mo Download Manager (MDM)</description>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level="asInvoker" uiAccess="false"/>
      </requestedPrivileges>
    </security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
    </application>
  </compatibility>
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*"/>
    </dependentAssembly>
  </dependency>
</assembly>
"#,
        );
        if let Err(e) = res.compile() {
            // Fallback for paths with spaces/parentheses where GNU windres fails on -I path
            let out_dir = std::path::PathBuf::from(std::env::var("OUT_DIR").unwrap());
            let tmp_dir = std::env::temp_dir().join("mdm_winres_build");
            let _ = std::fs::create_dir_all(&tmp_dir);
            let _ = std::fs::copy("icon.ico", tmp_dir.join("icon.ico"));
            let rc_src = if out_dir.join("main_res.rc").exists() {
                out_dir.join("main_res.rc")
            } else {
                out_dir.join("resource.rc")
            };
            if let Ok(rc_content) = std::fs::read_to_string(&rc_src) {
                let rc_file = tmp_dir.join("main_res.rc");
                let obj_file = tmp_dir.join("main_res.o");
                let lib_file = out_dir.join("libmain_res.a");
                let _ = std::fs::write(&rc_file, rc_content);
                let windres = std::env::var("RC").unwrap_or_else(|_| "windres.exe".to_string());
                let ar = std::env::var("AR").unwrap_or_else(|_| "ar.exe".to_string());
                let status = std::process::Command::new(&windres)
                    .current_dir(&tmp_dir)
                    .args(["--use-temp-file", "-i", "main_res.rc", "-o", "main_res.o"])
                    .status();
                if matches!(status, Ok(s) if s.success()) {
                    let _ = std::fs::remove_file(&lib_file);
                    let ar_status = std::process::Command::new(&ar)
                        .current_dir(&tmp_dir)
                        .args(["crs", lib_file.to_str().unwrap(), obj_file.to_str().unwrap()])
                        .status();
                    if matches!(ar_status, Ok(s) if s.success()) {
                        println!("cargo:rustc-link-search=native={}", out_dir.display());
                        println!("cargo:rustc-link-lib=static=main_res");
                        return;
                    }
                }
            }
            println!("cargo:warning=could not embed the Windows icon: {e}");
        }
    }
}
