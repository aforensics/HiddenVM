# HiddenVM

**HiddenVM** is an innovation in computing privacy.

Imagine you're entering a country at the airport. The border agents seize your laptop and force you to unlock it so that they can violate your privacy, treat you like a criminal, and [insult your humanity](https://www.reddit.com/r/privacy/comments/epblc8/australian_border_employee_hands_phone_back_to/). Is that the world you want to live in?

Whether you use Windows, macOS or Linux, now there's a tech solution for better privacy: **HiddenVM**.

**HiddenVM** is a simple, one-click, free and open-source Linux application that allows you to run Oracle's open-source [VirtualBox software](https://virtualbox.org) on the [Tails operating system](https://tails.boum.org).

This means you can run almost any OS as a VM inside the most anti-forensic computing environment in the world. Works where Tails does.

The VM will even connect to full-speed pre-Tor Internet by default, while leaving the Tor connection in Tails undisturbed.

To ensure anti-forensic deniability of your VMs, you can place your persistent HiddenVM installation - containing all VirtualBox binaries, VMs, and HiddenVM itself - in a [hidden VeraCrypt volume](https://www.veracrypt.fr/en/Hidden%20Volume.html), and only mount it in the amnesic Tails.

If you set it up correctly, when your computer is turned off all anyone can plausibly see is a blank Tails USB and a 'wiped' hard drive full of meaningless data, or a default booting decoy OS in a partition that you can create.

How does it feel to have *no* trace of your entire operating system - whether it's Windows, macOS or Linux - ever touch your hard drive? Now you can find out.

HiddenVM: *insanely private!*

## Installation and usage

- Boot into [Tails](https://tails.boum.org) on your computer and set an [admin password](https://tails.boum.org/doc/first_steps/startup_options/administration_password/index.en.html) for your session.

- [Do NOT use](#why-shouldnt-i-use-tails-official-persistent-volume-feature) Tails' [persistent volume feature](https://tails.boum.org/doc/first_steps/persistence/index.en.html).

- Create and mount a deniable, secure storage environment on internal or external media such as a [VeraCrypt](https://veracrypt.fr/en) volume.

- **[Download our latest release ZIP](https://github.com/aforensics/HiddenVM/releases)** and extract the archive.

- Run our AppImage file in the Files browser.

- Choose to store HiddenVM in your secure storage and it will download all binaries to launch VirtualBox.

- After first-time install you can then use HiddenVM offline where each AppImage launch takes about 2 minutes.

## How can I trust the HiddenVM AppImage file?

### You don't have to. Inspect our code:

- Open a Terminal and `cd` to the folder containing our AppImage.

- Run `mkdir inspect && sudo mount HiddenVM-*-x86_64.AppImage inspect -o offset=188456`

- Every file in the mounted folder can be inspected with a text editor. To search for IP addresses or web domains that HiddenVM could try to phone home to and violate your privacy, use [Searchmonkey](http://searchmonkey.embeddediq.com) (`sudo apt install searchmonkey`) to recursively search for `\.\S` in the mounted folder's files.

- Once you trust the current version of HiddenVM, when new releases arrive you can track code changes by using [Meld](https://meldmerge.org) (`sudo apt install meld`). Drag and drop the old and new folders together into *Meld*, and any code differences will be highlighted.

### And if you're precautious, check the integrity of our ZIP release file:

- Download both our ZIP and the MD5.

- Extract our AppImage and place it next to the MD5.

- Do `md5sum -c HiddenVM-*-x86_64.md5` and it will check both the ZIP and the AppImage.

### Or generate your own AppImage from our code after inspecting it:

1. `git clone https://github.com/aforensics/HiddenVM.git`

2. `cd HiddenVM/appimage`

3. `./make-appimage.sh` (The script will download **appimagetool** from [AppImageKit](https://github.com/AppImage/AppImageKit) if it needs to.)

See your own generated AppImage in the `target` subdir.

## FAQs / Warnings

### What type of person might use HiddenVM?

In the same way as Tor and Tails, **HiddenVM** (called **HVM** for short) is intended for a wide range of people and situations around the world. In our digital age of increasing surveillance and control, we need tools to keep digital privacy and freedom alive.

If you are a political dissident in a country under totalitarian rule, in your situation there has never been a robust tech solution to truly hide and protect your data in a convenient way. Our tool may provide that for you.

We are aligned with the Tails and Tor projects in our intention and promotion of how this software could and should be used.

### What guest OSes work with HiddenVM?

We have so far successfully tested Windows 10, macOS Mojave, Linux Mint, Ubuntu, Xubuntu, Fedora, and Whonix. Anything that works in VirtualBox should be compatible. Our Wiki will have how-to's and links for specific OSes. Please contribute interesting findings in [our subreddit](https://reddit.com/r/HiddenVM).

### How much RAM do I need?

Using VMs in Tails uses a lot of RAM because Tails already runs entirely in RAM. We recommended at least 16 GB in your machine but your mileage may vary.

### Why is HiddenVM taking more than the usual 2 minutes to launch?

The first time you run HiddenVM, the install can take anywhere from several minutes to more than half an hour because it needs to download all the necessary software that it uses. After that it caches everything offline for a much quicker 2-minute launch time.

Every 7 days, if you're connected to the Internet HiddenVM will do an `apt-get` update to check repositories like VirtualBox and will download new updates if available. Sometimes you can get connected to a very slow Tor circuit in Tails. Close off HiddenVM's Terminal window and restart Tails to hopefully be connected to a faster circuit.

Every time you do a Tails and HiddenVM upgrade, the first time after this will almost always need to install new package versions, thus taking around 5 minutes or longer. Then it returns to the usual 2 minutes.

### Can I use HiddenVM offline?

Yes. It may even be possible to use HVM offline for extended periods of several months at a time if you never update Tails or HiddenVM during such periods.

We can't guarantee this, but limited testing by the team has confirmed it being possible for at least a month.

As soon as you connect to the Internet, HiddenVM may upgrade its cached software and you may have to upgrade to the latest version from our GitHub as well as your Tails, but after all software is updated and verified as in sync by HiddenVM, it could be possible to use it offline for an extended period again.

### Known limitations:

- Currently, during HiddenVM's launch process doing certain tasks in Tails can crash your live session. It's not a serious limitation e.g. using Tails' Tor Browser does not cause the crash. The issue is caused by our complicated process of installing VirtualBox in Tails which temporarily upgrades and then restores the original versions of dependencies used by certain GNOME apps. When HiddenVM finishes its launch you can resume all activity in Tails again. We hope we can remove this limitation in a future HiddenVM redesign.

### 'Extras' and 'Dotfiles' feature

HiddenVM allows you to fully automate the customization of your Tails environment at every launch by performing system settings modifications or loading additional software including persistent config files for such software.

Go to 'extras' folder in your HiddenVM and rename `extras-example.sh` to `extras.sh`. Any lines you add will be performed as bash script code at the end of each subsequent HiddenVM launch, right after it opens VirtualBox.

Some examples:

```
sudo apt-get install autokey-gtk -y #Install a popular Linux universal hotkeys tool
```

```
nohup autokey & #Launch the Linux universal hotkeys tool that Extras just installed
```

```
gsettings set org.gnome.desktop.interface enable-animations false #Turn off GNOME animations
```

Eventually we will have a Wiki page with many Extras examples. Please contribute ideas. The installation and launching of a pre-VirtualBox VPN could be possible.

Warning: Make sure your commands work or it can cause HiddenVM to produce errors or not fully exit its Terminal.

**Dotfiles:** Inside 'extras' is the 'dotfiles' folder. Place any files or folder structures in there and HiddenVM will recursively symlink them into your Tails session's Home folder at `/home/amnesia`. This is a very powerful feature. By putting a *.config* folder structure in there you can have all your additional software settings pre-loaded before they're installed via Extras.

### Why shouldn't I use Tails' official persistent volume feature?

Tails' [Additional Software](https://tails.boum.org/doc/first_steps/additional_software/index.en.html#index1h2) feature disturbs HiddenVM's complicated `apt-get update` wizardry that achieves our VirtualBox-installing breakthrough.

More importantly, our intention is for HVM's virtual machines to be truly 'hidden', i.e. forensically undetectable. This is the first time you can emulate VeraCrypt's Windows [Hidden OS](https://www.veracrypt.fr/en/VeraCrypt%20Hidden%20Operating%20System.html) feature, but this time the plausible deniability hasn't been [broken by security researchers](https://www.researchgate.net/publication/318155607_Defeating_Plausible_Deniability_of_VeraCrypt_Hidden_Operating_Systems) and it's for any OS you want.

Due to using LUKS encryption, Tails' persistent volume feature currently offers no anti-forensics for the data in that area of your Tails stick, and is therefore not airport border inspection proof. If that ever changes, we would prefer to integrate HiddenVM more elegantly into Tails' existing infrastructure, and we appreciate the wonderful work the Tails devs do.

### Can I install the Extension Pack in HiddenVM's VirtualBox?

Yes. To permanently add it, edit the `env` file in your HiddenVM folder and change the `INSTALL_EXT_PACK=` line from `"false"` to `"true"`. Then quit VirtualBox if it's open and execute the AppImage once more.

In order to run macOS in VirtualBox, you need to use the Extension Pack.

### Are HVM's virtual machines protected by Tails' Tor connection?

No, and this is actually a bonus. By having normal full-speed Internet in any VM as the default, you can pretend it's a normal computer on your network but actually it's protected inside the anti-forensic environment of Tails.

You can still Torify a VM by [simply linking it to a Whonix-Gateway VM](https://whonix.org/wiki/Other_Operating_Systems). You can have the best of both worlds. But be careful, don't use a VM with clearnet Internet and then later with Torification, or vice versa, if anonymity is a concern.

### But doesn't Whonix inside Tails mean Tor-over-Tor?

Due to HiddenVM's design, fortunately no. Because it connects to pre-Tor 'clearnet' Internet by default, Whonix-Gateway will connect independently of Tails' own Tor process, making both able to co-exist in the one environment.

### Full DNS Internet doesn't work in VMs by default. How do I enable it?

HiddenVM's clearnet Internet doesn't pass on DNS resolution by default. To get normal full Internet working in a non-Torified VM, manually set DNS servers in its system network settings to anything like Cloudflare's `1.1.1.1` and `1.0.0.1`. We might be able to fix this problem in the future.

Note: This is not an issue for Whonix-Gateway which resolve hostnames via its own Tor process inside the VM. Whonix-Workstation then points to Gateway for its DNS, as will any other Gateway-Torified VMs.

### Is HiddenVM risky software that undermines the safety of Tails?

We do change a few security settings in the Tails Debian system in order to make HiddenVM do its thing. Apart from the fact that you can inspect our code, we'll add to our Wiki the list of exactly what HiddenVM temporarily modifies in your Tails environment from a security standpoint, so that you can know exactly what's going on.

E.g. HiddenVM hooks into Tails' ['clearnet' user](https://tails.boum.org/contribute/design/Unsafe_Browser/#index2h2) infrastructure, which some people are already concerned about existing in Tails.

We also increase the `sudo` timeout to improve the user experience to only require password authentication one time. This is because HiddenVM can sometimes take a while to do its thing when initially installing or during weekly updates. This timeout is not normally extended in Tails' Debian environment and it may give elevated privileges to malware you could accidentally download in your main Tails environment.

In the end, the thing that controls your safely more than anything else is what you do or download in Tails. We and the Tails project can only help you so much.

As a result, we strongly suggest minimal usage of outer Tails Internet activity when using HVM. Tails' attack surface is already wide and HVM makes that a little wider. To do significant Tor Browser or other Internet-connected activity in Tails outside of HiddenVM, boot into a new Tails session and don't launch HiddenVM.

### Is HiddenVM a slap in the face to the whole idea of Tails?

No, HiddenVM is just an innovative and unexpected use of Tails that people didn't think was possible.

Our project actually pays a high compliment to Tails. We're promoting Tails as an entire platform and ecosystem for aforensic computing, which expands the vision of its benefits for the world. We trust and humbly rely on Tails, Tor, Debian and Linux as upstream projects and we feel an extreme sense of responsibility with what we're doing.

We take user privacy, security, and anonymity very seriously and will implement updates to improve the default safety for HiddenVM users over time. For now, we invite you to inspect our code and offer suggestions and contributions that improve security without removing functionality or features.

Furthermore, HiddenVM could attract new users to the Tails user base, which would increase its anonymity set, which is beneficial for the Tails community.

Although we don't use Tails' Tor for our main Tor computing and we prefer HVM Whonix instead, we are still promoting and making use of Tails' Tor as a fundamental part of downloading and setting up HiddenVM. Due to Tails being amnesic and connecting to the Tor network by default, it's an incredibly safe environment to set up a computer using HiddenVM, and we are promoting this. 

As such, we are normal Tails users and advocates ourselves.

### Limitation of efficacy

Your data is not 'private' or 'hidden' during your use of your computer with your VeraCrypt volume unlocked. The privacy only applies to when your computer is turned off, or turned on but with the private data in your VeraCrypt volume not unlocked after turning it on.

'Deniability' is very complex. There are many threat models and situations. There is no one-size-fits-all method of effective deniability. How 'normal' or 'plausible' your computer or data must convincingly appear to be, when turned off or forced to be turned on, entirely depends on your circumstances and who your 'enemy' is.

Our claim of effective deniability is a very broad one and might not apply to your particular scenario. We might not be able to cater to your scenario but we are very interested in studying it and our Wiki could become a place to document various scenarios and solutions for deniability in the context of HiddenVM.

The Tails project lists other limitations and warnings which may apply. [Please read them](https://tails.boum.org/doc/about/warning/index.en.html).

## Disclaimer

Despite our grand words earlier in this README, any software project claiming increased security, privacy or anonymity can never provide a guarantee for such things, and we are no different here.

As our license states, we are not liable to you for any damages as a result of using our software. Similarly, any claims by our project or its representatives are personal opinions and do not constitute legal advice or digital security advice.

The HiddenVM project provides no guarantee of any security, privacy or anonymity as a result of you using our software. You use our software at your own risk, and if or how you use it is your own discretion.
