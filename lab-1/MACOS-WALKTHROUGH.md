# XAMPP assignment walkthrough (macOS)

The class handout shows Windows, but this computer is an Apple Silicon Mac. The
required results are the same; the names and locations of the controls differ.

## 1. Install XAMPP

1. Open `xampp-osx-8.2.4-0-installer.dmg` from Downloads.
2. Open the installer inside the disk image. If macOS blocks it, Control-click
   the installer, choose **Open**, and confirm **Open**.
3. Enter the Mac administrator password when asked.
4. Keep the default components and destination, then complete the installer.

XAMPP installs at `/Applications/XAMPP` on macOS. The downloaded file is the
native installer; do not choose XAMPP-VM on an Apple Silicon Mac.

## 2. Start the local server

1. Open `/Applications/XAMPP/manager-osx.app`.
2. Select **Manage Servers**.
3. Select **Apache Web Server**, then click **Start**.
4. Select **MySQL Database**, then click **Start**.
5. Leave both running until the screenshots are finished.

## 3. Check XAMPP

Open `http://localhost/dashboard/` in a browser. The XAMPP welcome page should
appear.

## 4. Check the class page

Open `http://localhost/project/index.php`. The page should display **Devin
Thomas**.

## 5. Capture the rubric screenshots

Take screenshots that clearly show:

1. XAMPP Manager with Apache and MySQL running.
2. The XAMPP welcome page with `localhost/dashboard/` visible in the address bar.
3. The Devin Thomas page with `localhost/project/index.php` visible in the
   address bar.

On macOS, press **Shift-Command-4**, then press **Space**, and click a window to
capture that complete window. Keep the browser toolbar visible.

## 6. Finish

Stop Apache and MySQL in XAMPP Manager after the screenshots are saved. XAMPP is
for local development, not for hosting this project publicly.
