import { expect } from "chai";
import hre from "hardhat";
const { ethers, networkHelpers } = await hre.network.create();

describe("Escrow", function () {
  async function deployEscrowFixture() {
    const [depositor, beneficiary, arbiter, other] = await ethers.getSigners();

    const escrow = await ethers.deployContract(
      "Escrow",
      [beneficiary.address, arbiter.address],
      { value: ethers.parseEther("1.0") }
    );

    return { escrow, depositor, beneficiary, arbiter, other };
  }

  describe("Deployment", function () {
    it("Should set the right beneficiary, arbiter, and depositor", async function () {
      const { escrow, depositor, beneficiary, arbiter } = await networkHelpers.loadFixture(deployEscrowFixture);
      expect(await escrow.depositor()).to.equal(depositor.address);
      expect(await escrow.beneficiary()).to.equal(beneficiary.address);
      expect(await escrow.arbiter()).to.equal(arbiter.address);
    });

    it("Should hold the deposited funds", async function () {
      const { escrow } = await networkHelpers.loadFixture(deployEscrowFixture);
      expect(await escrow.getBalance()).to.equal(ethers.parseEther("1.0"));
    });

    it("Should fail if deployed with zero value", async function () {
      const [, beneficiary, arbiter] = await ethers.getSigners();
      await expect(
        ethers.deployContract("Escrow", [beneficiary.address, arbiter.address], { value: 0n })
      ).to.be.revertedWith("Must deposit some Ether");
    });
  });

  describe("approve()", function () {
    it("Should revert if called by non-arbiter", async function () {
      const { escrow, other } = await networkHelpers.loadFixture(deployEscrowFixture);
      await expect(escrow.connect(other).approve())
        .to.be.revertedWith("Only the arbiter can call this function");
    });

    it("Should release funds to beneficiary and emit Approved", async function () {
      const { escrow, arbiter, beneficiary } = await networkHelpers.loadFixture(deployEscrowFixture);
      await expect(escrow.connect(arbiter).approve())
        .to.emit(escrow, "Approved")
        .withArgs(ethers.parseEther("1.0"));

      expect(await escrow.getBalance()).to.equal(0);
    });

    it("Should revert if called twice", async function () {
      const { escrow, arbiter } = await networkHelpers.loadFixture(deployEscrowFixture);
      await escrow.connect(arbiter).approve();
      await expect(escrow.connect(arbiter).approve())
        .to.be.revertedWith("Escrow has already been resolved");
    });
  });

  describe("refund()", function () {
    it("Should return funds to depositor and emit Refunded", async function () {
      const { escrow, depositor, arbiter } = await networkHelpers.loadFixture(deployEscrowFixture);
      await expect(escrow.connect(arbiter).refund())
        .to.emit(escrow, "Refunded")
        .withArgs(ethers.parseEther("1.0"));

      expect(await escrow.getBalance()).to.equal(0);
    });
  });
});