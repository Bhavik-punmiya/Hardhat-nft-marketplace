const {assert, expect } = require("chai")
const {network, deployments, ethers, getNamedAccounts } = require("hardhat")
const {developmentChains} = require("../../helper-hardhat-config")

!developmentChains.includes(network.name) ? describe.skip : describe("NftMarketPlace Test" , function () {
    let nftMarketPlaceContract , nftMarketPlace, basicnft, deployer, player
    const Price = ethers.utils.parseEther("0.1")
    const TokenId = 0
    beforeEach(async function(){
        deployer = (await getNamedAccounts()).deployer
        // player = await getNamedAccounts().player
        const accounts = await ethers.getSigners()
        player = accounts[1]
        await deployments.fixture(["all"])
        nftMarketPlace = await ethers.getContract("NftMarketplace")

        basicnft = await ethers.getContract("BasicNft")
        await basicnft.mintNft()
        await basicnft.approve(nftMarketPlace.address, TokenId)
    })
    it("lists and can be bought ", async function(){
        await nftMarketPlace.listItem(basicnft.address, TokenId, Price)
        const playerConnectedNftMarketPlace  = await nftMarketPlace.connect(player)
        await playerConnectedNftMarketPlace.buyItem(basicnft.address, TokenId , {value : Price})
        const newOwner = await basicnft.ownerOf(TokenId)
        const deployerProceeds = await nftMarketPlace.getProceeds(deployer)
        assert(newOwner.toString() == player.address)
        assert(deployerProceeds.toString() == Price.toString())

    })
})