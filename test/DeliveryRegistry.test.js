const { expect } = require('chai');
const { ethers } = require('hardhat');
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers');

const digestOf = (text) => ethers.keccak256(ethers.toUtf8Bytes(text));

describe('DeliveryRegistry', function () {
  async function deployed() {
    const [owner, worker, stranger] = await ethers.getSigners();
    const registry = await (await ethers.getContractFactory('DeliveryRegistry')).deploy();
    return { registry, owner, worker, stranger };
  }

  describe('deployment', function () {
    it('leaves the deployer as owner and writer', async function () {
      const { registry, owner } = await loadFixture(deployed);
      expect(await registry.owner()).to.equal(owner.address);
      expect(await registry.isWriter(owner.address)).to.equal(true);
      expect(await registry.total()).to.equal(0n);
    });
  });

  describe('register', function () {
    it('stores the record and emits the event', async function () {
      const { registry, owner } = await loadFixture(deployed);
      const digest = digestOf('acta de entrega 001');

      await expect(registry.register(digest, 'obra 001'))
        .to.emit(registry, 'Registered')
        .withArgs(digest, owner.address, (t) => t > 0n, 'obra 001');

      const [exists, timestamp, author, label] = await registry.verify(digest);
      expect(exists).to.equal(true);
      expect(timestamp).to.be.greaterThan(0n);
      expect(author).to.equal(owner.address);
      expect(label).to.equal('obra 001');
      expect(await registry.total()).to.equal(1n);
    });

    it('refuses the same document twice', async function () {
      const { registry } = await loadFixture(deployed);
      const digest = digestOf('duplicada');
      await registry.register(digest, 'primera');
      await expect(registry.register(digest, 'segunda'))
        .to.be.revertedWithCustomError(registry, 'AlreadyRegistered');
      expect(await registry.total()).to.equal(1n);
    });

    it('refuses an empty hash', async function () {
      const { registry } = await loadFixture(deployed);
      await expect(registry.register(ethers.ZeroHash, 'vacía'))
        .to.be.revertedWithCustomError(registry, 'EmptyDigest');
    });

    it('refuses an account without writing rights', async function () {
      const { registry, stranger } = await loadFixture(deployed);
      await expect(registry.connect(stranger).register(digestOf('ajena'), 'x'))
        .to.be.revertedWithCustomError(registry, 'NotWriter');
    });
  });

  describe('verify', function () {
    it('answers false for an unknown document instead of reverting', async function () {
      const { registry } = await loadFixture(deployed);
      const [exists, timestamp, author, label] = await registry.verify(digestOf('nunca registrada'));
      expect(exists).to.equal(false);
      expect(timestamp).to.equal(0n);
      expect(author).to.equal(ethers.ZeroAddress);
      expect(label).to.equal('');
    });
  });

  describe('permissions', function () {
    it('lets the owner add and remove writers', async function () {
      const { registry, worker } = await loadFixture(deployed);

      await expect(registry.setWriter(worker.address, true))
        .to.emit(registry, 'WriterUpdated').withArgs(worker.address, true);
      await registry.connect(worker).register(digestOf('del operario'), 'obra 002');
      expect(await registry.total()).to.equal(1n);

      await registry.setWriter(worker.address, false);
      await expect(registry.connect(worker).register(digestOf('otra'), 'obra 003'))
        .to.be.revertedWithCustomError(registry, 'NotWriter');
    });

    it('does not let anyone else change permissions', async function () {
      const { registry, stranger, worker } = await loadFixture(deployed);
      await expect(registry.connect(stranger).setWriter(worker.address, true))
        .to.be.revertedWithCustomError(registry, 'NotOwner');
    });

    it('rejects the zero address', async function () {
      const { registry } = await loadFixture(deployed);
      await expect(registry.setWriter(ethers.ZeroAddress, true))
        .to.be.revertedWithCustomError(registry, 'ZeroAddress');
    });
  });

  describe('transferOwnership', function () {
    it('moves ownership and leaves the new owner able to write', async function () {
      const { registry, owner, worker } = await loadFixture(deployed);

      await expect(registry.transferOwnership(worker.address))
        .to.emit(registry, 'OwnershipTransferred').withArgs(owner.address, worker.address);

      expect(await registry.owner()).to.equal(worker.address);
      expect(await registry.isWriter(worker.address)).to.equal(true);

      await expect(registry.connect(owner).setWriter(owner.address, false))
        .to.be.revertedWithCustomError(registry, 'NotOwner');
    });
  });
});
