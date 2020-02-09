# HiddenVM

**HiddenVM** is an innovation in computing privacy.

Imagine you're entering a country at the airport. The border agents seize your laptop and force you to unlock it, so that they can violate your privacy, treat you like a criminal, and [insult your humanity](https://www.reddit.com/r/privacy/comments/epblc8/australian_border_employee_hands_phone_back_to/). Is that the world we want to live in?

Whether you use Windows, macOS or Linux, now there's a tech solution for true privacy: **HiddenVM**.

**HiddenVM** is a simple, one-click, free and open-source Linux application that allows you to run Oracle's open-source [VirtualBox software](https://virtualbox.org) on the [Tails operating system](https://tails.boum.org).

This means you can run almost any OS as a VM inside the most anti-forensic computing environment in the world. Works where Tails does.

The VMs even use your full-speed non-Tor Internet by default, while leaving the Tails' outer Tor connection undisturbed.

To ensure anti-forensic deniability of your VMs you can place your persistent HiddenVM installation - containing all VirtualBox files, the VMs, and HiddenVM itself - in a [hidden VeraCrypt volume](https://www.veracrypt.fr/en/Hidden%20Volume.html) and only mount it when using the amnesic Tails.

When your computer is turned off, all anyone can plausibly see is a blank Tails USB and a hard drive full of meaningless data or a bootable decoy OS partition that you can create.

How does it feel to have no forensic trace of your entire operating system - whether it be Windows, macOS or Linux - ever touch your hard drive?

Now you can find out.

True privacy in computing, finally here.
## Installation and usage

- Boot into Tails on your computer and set an [administration password](https://tails.boum.org/doc/first_steps/startup_options/administration_password/index.en.html) for your session

- Don't use the [persistent volume feature](https://tails.boum.org/doc/first_steps/persistence/index.en.html) (Make a different Tails stick specifically for HiddenVM)

- Create and mount a secure storage environment on internal or external media such as a VeraCrypt volume

- Download *HiddenVM-\*-x86_64.AppImage.zip* from the [latest release](https://github.com/aforensics/HiddenVM/releases) and extract using the archive manager

- Run *HiddenVM-\*-x86_64.AppImage* from the file browser

- Choose where to store your persistent HiddenVM installation and it will download all binaries to launch VirtualBox

- After first-time install you can use HiddenVM offline and each launch takes around 2 minutes

## How can I trust the HVM AppImage file?

**You don't have to. Inspect our code:**

- Open a Terminal and `cd` to the folder containing our .AppImage

- Run `mkdir inspect && sudo mount HiddenVM-*-x86_64.AppImage inspect -o offset=188392`

- Every file in the mounted folder can be inspected with a text editor. To search for IP addresses or web domains HiddenVM could try to phone home to, use *Searchmonkey* (`sudo apt install searchmonkey`) and recursively search for `\.\S` in the mounted folder's files.

- Once you trust the current version of HVM, when new releases arrive you can track code changes by using *Meld* (`sudo apt install meld`). Drag and drop the old and new folders together into *Meld*, and any code differences will be highlighted.

**Or generate your own AppImage from our code after inspecting it:**

1. `git clone https://github.com/aforensics/HiddenVM.git`

2. `cd HiddenVM/appimage`

3. `./make-appimage.sh` (It may need to download **appimagetool** from [AppImageKit](https://github.com/AppImage/AppImageKit) as part of the process)

Find your own AppImage in `target` subdir






