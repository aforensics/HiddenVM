# HiddenVM

**HiddenVM** is an innovation in computing privacy.

Imagine you're entering a country at the airport. The border agents seize your laptop and force you to unlock it, so that they can violate your privacy, treat you like a criminal, and [insult your humanity](https://www.reddit.com/r/privacy/comments/epblc8/australian_border_employee_hands_phone_back_to/). Is that the world we want to live in?

Whether you use Windows, macOS or Linux, now there's a tech solution for real privacy: **HiddenVM**.

**HiddenVM** is a simple, one-click, free and open-source Linux application that allows you to run Oracle's open-source [VirtualBox software](https://virtualbox.org) on the [Tails operating system](https://tails.boum.org).

This means you can run almost any OS in a VM inside the most anti-forensic computing environment in the world. Works where Tails does.

The VM even uses your full-speed pre-Tor Internet by default, while leaving the Tails outer Tor connection undisturbed.

To ensure anti-forensic deniability of your VMs, you can place your persistent HiddenVM installation - containing all VirtualBox files, the VMs, and HiddenVM itself - in a [hidden VeraCrypt volume](https://www.veracrypt.fr/en/Hidden%20Volume.html), and only mount it when using the amnesic Tails.

When your computer is turned off, all anyone can plausibly see is a blank Tails USB and a hard drive full of meaningless data or a bootable decoy OS partition that you can create.

How does it feel to have no forensic trace of your entire operating system - whether it's Windows, macOS or Linux - ever touch your hard drive?

Now you can find out. True privacy in computing, finally here.

## Installation and usage

- Boot into Tails on your computer and set an [administration password](https://tails.boum.org/doc/first_steps/startup_options/administration_password/index.en.html) for your session

- Don't use the [persistent volume feature](https://tails.boum.org/doc/first_steps/persistence/index.en.html) (Make a different Tails stick specifically for HiddenVM)

- Create and mount a secure storage environment on internal or external media such as a VeraCrypt volume

- Download *HiddenVM-\*-x86_64.AppImage.zip* from the [latest release](https://github.com/aforensics/HiddenVM/releases) and extract using the archive manager

- Run *HiddenVM-\*-x86_64.AppImage* from the file browser

- Choose where to store your persistent HiddenVM installation and it will download all binaries to launch VirtualBox

- After first-time install you can use HiddenVM offline and each launch takes around 2 minutes

## How can I trust the Hidden AppImage file?

### You don't have to. Inspect our code:

- Open a Terminal and `cd` to the folder containing our .AppImage

- Run `mkdir inspect && sudo mount HiddenVM-*-x86_64.AppImage inspect -o offset=188456`

- Every file in the mounted folder can be inspected with a text editor. To search for IP addresses or web domains HiddenVM could try to phone home to, use *Searchmonkey* (`sudo apt install searchmonkey`) and recursively search for `\.\S` in the mounted folder's files.

- Once you trust the current version of HVM, when new releases arrive you can track code changes by using *Meld* (`sudo apt install meld`). Drag and drop the old and new folders together into *Meld*, and any code differences will be highlighted.

### Or generate your own AppImage from our code after inspecting it:

1. `git clone https://github.com/aforensics/HiddenVM.git`

2. `cd HiddenVM/appimage`

3. `./make-appimage.sh` (It may need to download **appimagetool** from [AppImageKit](https://github.com/AppImage/AppImageKit) as part of the process)

Find your own AppImage in `target` subdir

## FAQs / Warnings

### What guest operating systems work with HiddenVM?

So far we have successfully tested Windows 10, macOS Mojave, Linux Mint, Ubuntu, Xubuntu, Fedora, and Whonix. Anything that works in VirtualBox should be compatible. Our wiki will have how-to's and links for specific OSes. Please contribute knowledge in our [subreddit](https://reddit.com/r/HiddenVM).


### How much RAM do I need?

Using VMs in Tails uses a lot of RAM because Tails already runs entirely in RAM. We recommended at least 16 GB in your machine, but your mileage may vary.


### Why is HVM taking more than the normal 2 minutes to launch?

Every 7 days, if you're connected to the Internet HVM will do an `apt-get` update to check repositories like VirtualBox and will download new updates if available. Sometimes you can get connected to a very slow Tor circuit in Tails. Close off HVM's Terminal window and restart Tails to hopefully be connected to a faster circuit.


### HVM 'Extras' and 'Dotfiles' feature

HVM allows you to fully automate the customization of your Tails environment at every launch by performing system settings modifications or loading additional software including persistent config files for them.

Go to 'extras' folder in your HVM and rename `extras-example.sh` to `extras.sh`. Any lines you add will be performed as bash script code right after it opens VirtualBox, at the end of each subsequent HVM launch.

Some examples:

```
sudo apt-get install autokey-gtk -y #Install a popular Linux hotkeys tool
```

```
nohup autokey & #Then launch that package that Extras installed
```

```
gsettings set org.gnome.desktop.interface enable-animations false #Turn off sluggish GNOME animations
```

```
#Set Tails Tor Browser 'Security Level' to 'Safest' and disable JavaScript
CONFIG_FILE=/home/amnesia/.tor-browser/profile.default/user.js
echo -e "user_pref(\"extensions.torbutton.security_slider\", 1);" >> "$CONFIG_FILE"
echo -e "user_pref(\"javascript.enabled\", false);" >> "$CONFIG_FILE"
```

Eventually we will have a Wiki page with many Extras examples. Please contribute ideas. The installation and launching of a pre-VirtualBox VPN could be possible.

Warning: Make sure your commands work or it may cause HVM to not fully exit its Terminal or produce errors.

**Dotfiles:** Inside 'extras' is a 'dotfiles' folder. Place any files and folder structures in there and HVM will recursively symlink it into the temporary Tails Home folder at `/home/amnesia`. This feature is very powerful and allows full additional software settings to be pre-loaded before they're install via Extras if you make a *.config* folder structure in there.


### Why shouldn't I use the official Tails persistent volume feature?

Tails' [Additional Software](https://tails.boum.org/doc/first_steps/additional_software/index.en.html#index1h2) feature disturbs HVM's complicated `apt-get update` sorcery that achieves our VirtualBox-installing breakthrough. More importantly, our intention is for HVM virtual machines to be truly 'hidden', i.e. forensically invisible.

This is the first time you can emulate VeraCrypt's [Hidden OS](https://www.veracrypt.fr/en/VeraCrypt%20Hidden%20Operating%20System.html) feature for Windows, but now for any OS (and also without its plausible deniability being [broken by security researchers](https://www.researchgate.net/publication/318155607_Defeating_Plausible_Deniability_of_VeraCrypt_Hidden_Operating_Systems)). 

Due to using LUKS encryption, Tails' persistent volume feature currently offers no anti-forensics for the data on that area of your Tails stick, and is therefore not airport border inspection proof. If that ever changes we would prefer to integrate HVM more elegantly into Tails' existing infrastructure and we appreciate the amazing work that Tails devs continue to do.


### Can I install the Extension Pack in HVM's VirtualBox?

Yes. To permanently add it, edit the `env` file in your HVM dir and change the `INSTALL_EXT_PACK=` line from `"false"` to `"true"`. Then quit VirtualBox if open, and execute the HVM AppImage once more.

In order to run macOS in VirtualBox, you need to use the Extension Pack.


### Are VMs in HVM's VirtualBox protected by the Tails Tor connection?

No, and this is actually a bonus. By having normal full-speed Internet in any VM you want, you can pretend it's a normal computer on your network but actually it's protected inside the incredibly anti-forensic environment of Tails.

You can still Torify any VM by [simply linking it to a Whonix-Gateway VM](https://whonix.org/wiki/Other_Operating_Systems). You can have the best of both worlds. But be careful, don't use a VM with clearnet Internet and then later with Torification, or vice versa, if anonymity is a concern.


### But doesn't Whonix inside Tails mean Tor-over-Tor?

With HVM's design, fortunately no. Because it connects to 'clearnet' pre-Tor Internet by default, Whonix-Gateway will connect independently of Tails' Tor process, making both able to co-exist in the one environment.


### Full Internet with DNS doesn't work in VMs by default, how do I enable it?

HVM's clearnet Internet doesn't pass DNS resolution on by default. To get normal full Internet working in any non-Torified VM, manually set the DNS servers in network settings to something like Cloudflare's `1.1.1.1` and `1.0.0.1`. We might be able to remove this kink in the future.

Note: This is not an issue for Whonix-Gateway which uses its own Tor process inside the VM to resolve hostnames. Whonix-Workstation points to Gateway for its DNS, as will any other Gateway-Torified VMs you use.


### Is HVM risky software that undermines the safety of Tails?

We do indeed change a few security settings in the Tails Debian system in order to make HVM do its thing. Apart from the fact that you can inspect our code, we'll soon add to our Wiki the list of exactly what HVM temporarily modifies in your Tails environment from a security standpoint so that you can know exactly what's going on.

HVM e.g. hooks into the ['clearnet' user](https://tails.boum.org/contribute/design/Unsafe_Browser/#index2h2) infrastructure in Tails, which some people are already concerned about it even existing.

We also increase the sudo timeout to improve the user experience to only require password authentication one time, and because when installing HVM or during weekly updates it can sometimes take a while to do its thing. This timeout is not normally extended in the Tails Debian environment and this may leave elevated privileges available to malware you could accidentally download in your Tails environment.

In the end, the factor that controls your safely more than anything else is what you choose to do in Tails. We and the Tails project can only help you so much.

As a result, we strongly suggest minimal usage of regular Internet activity in Tails when also using HVM. The attack surface is already wide in Tails, and HVM makes that a little wider. To do significant Tor Browser or other Internet-connected activity in the Tails host, boot into a Tails session without launching HVM.

We also encourage you to read Tails' long [Warnings](https://tails.boum.org/doc/about/warning/index.en.html) page.


### Is HVM a slap in the face to the entire idea of Tails?

No. HiddenVM is just an innovative and unexpected use of Tails that no one previously thought possible.

Our project is actually a paying of the highest compliment to Tails. We're promoting Tails as a new platform and entire ecosystem for aforensic computing, to do things that Tails never dreamed of. We trust and humbly rely on Tails, Debian, Tor and Linux as upstream projects and we feel an extreme sense of responsibility around what we're doing.

We take user privacy, security, and anonymity very seriously and we will implement updates to improve the default safety of HVM over time. For now we invite you to inspect our code and offer suggestions and contributions that improve security without removing functionality or features.

Furthermore, HVM may attract more users to the Tails user base, which will enlarge its anonymity set, which is a needed thing for the Tails community. And although we don't use the Tails Tor environment for our main computing and we prefer HVM Whonix instead, we are still promoting and making use of Tails as a fundamental part of the process to download and set up a HiddenVM, where as the host OS it is an incredibly safe environment to do such a thing.

As such, we are normal Tails users and advocates just like anyone else.
