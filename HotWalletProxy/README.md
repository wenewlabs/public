# HotWalletProxy

### The Problem

It's common in web3 to keep your high value NFTs in a cold wallet. Many web3 apps require you to own
an NFT to use their app. How can you keep your cold wallet secure, while still proving you have
ownership of these NFTs?

### The Solution (or at least, a solution)

`HotWalletProxy` is a contract that provides a proxy for web3 apps to verify ownership of an NFT,
using the owner's hot wallet.

![HotWalletProxy Diagram](https://github.com/wenewlabs/public/blob/main/HotWalletProxy/images/diagram.jpg)

### Questions/Feedback

We would love to hear your thoughts and comments on this first draft of the contract. The more eyes we have on it,
the better we'll feel that it's going to do what it purports to do.

### FAQ

**Q**: Why would I do this?

**A**: With one transaction (or signed message) from your cold wallet, you'll be able to use your hot wallet to act as the owner of your cold wallet's NFTs. At minimum, we'll be using this at [10KTF][https://10ktf.com/].

**Q**: Why are there two methods to set hot wallets?

**A**: One method is for people who are comfortable submitting a transaction from their cold wallets. The other, which uses a signed message, can be submitted from any wallet. The expected use case here is for someone who has an air-gapped cold wallet, and has the technical expertise to generate a signed message themselves. This method allows someone to verify ownership of their cold wallet, without it ever touching the network. We'll be putting together a self-contained UX for people who don't have the technical skills, which they can put on a USB stick and access on their air-gapped machine so getting the signature isn't as onerous.

**Q**: Why would you link my cold/hot wallets together? I don't want people to know what I'm up to.

**A**: For privacy purposes, we wrote this contract with the expectation that you would have a public cold/hot wallet pair, and another cold/hot wallet pair that's kept private (e.g. funded strictly through Tornado Cash, or something similar).

**Q**: Where is this deployed?

**A**: We're currently open for comments and review from the public, and will be getting a third-party audit for the contract. Once this is complete, we'll publish to both mainnet and Rinkeby, and will publish the address so everyone can make use of it.
