# Dependencies

You need to install NodeJS from https://nodejs.org/, truffle via command `npm i -g truffle ` in the terminal.

You need to create account at [infura](https://infura.io/) for smart contract deployment.

You need [metamask](https://metamask.io/) installed in your browser and you need some rinkeby ether for gas (may be obtained from [here](https://www.rinkeby.io/#faucet)).


# Smart contract deployment

To deploy smart contract on rinkeby network clone this repository and launch in the terminal following command from root folder of repository:

```bash
npm i
(export INFURA_TOKEN=$INFURA_TOKEN; export ETH_KEY=$ETH_KEY; truffle migrate --reset --network rinkeby)
````

Where $INFURA_TOKEN is access token you could obtain from [infura](https://infura.io/) and $ETH_KEY is your ethereum private key.

Deployment script prints to the terminal following log
```bash
Using network 'rinkeby'.

Running migration: 1_initial_migration.js
  Deploying Migrations...
  ... 0xfe81602413758016aebf9d5ee1314c17a91d2cb9182977f004b16fa7a101d979
  Migrations: 0x6d4968bb5cc23aba53bf3e1772493b5a4a252641
Saving successful migration to network...
  ... 0x8767b839776860abc65be45b868694d0821afe8970dea5f250d1df12531e1ad1
Saving artifacts...
Running migration: 2_deploy_fund.js
  Deploying CryptoYen...
  ... 0xc48d0b8edfbeb3e6b37bf6b8a40904b873ed79589ee7846823f3912583ae09f1
  CryptoYen: 0xe9b49a8947077ede9817a3a0d8978e0f7f124487
Saving successful migration to network...
  Deploying Fund...
  ... 0x53cf0b6680ad9505378a17f5a6419bccce4bb6a707e74cfb2e78eadbf4c8ac33
  ... 0xc40c318a402e02f97070408512102eeb72d5e55fe9cceb228fae450354885ba5
Saving artifacts...
  Fund: 0x4f724a33a013a4dfca92e57d4f3167733c6614ff
  ... 0x96757ea88eb211e4b051b1de5d94c7cd3d687d8e21cf91b6b0883cb3d9a726d6
  ```
  
  There are two smart contracts, CryptoYen and Fund with addresses `0xe9b49a8947077ede9817a3a0d8978e0f7f124487` and `0x4f724a33a013a4dfca92e57d4f3167733c6614ff` (during your own deployment there will be other addresses). You may use these addresses to interact with smart contract.
 


# Interacting with smart contract

CryptoYen is standard mintable ERC20 token contract. And Fund is contract managing the fund. You may get actual information about CryptoYen from etherscan. For previous example the url is https://rinkeby.etherscan.io/token/0xe9b49a8947077ede9817a3a0d8978e0f7f124487 . To interact with fund contract open https://trustpoc.bankex.com/ and type here address of Fund smart contract (or type something like https://trustpoc.bankex.com/?contract=0x4f724a33a013a4dfca92e57d4f3167733c6614ff). You need  [Metamask](https://metamask.io) extension installed with active rinkeby network and same wallet as you use during deplyment. Then init smart contract with initData.csv and initBenefeteary.csv files stored in csv folder in the repository. 
As a result you can manage fund, obtain reports and update fund state with OBK_$date.csv files.

# Source code of the dApp.

Source code of the dApp is available at https://github.com/BANKEX/trustpoc_frontend .
