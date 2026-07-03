import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Escrow", (m) => {
  const deployer = m.getAccount(0);

  // Addresses for the beneficiary and arbiter — replace with real values,
  // or expose them as parameters (see note below)
  const beneficiary = m.getAccount(1);
  const arbiter = m.getAccount(2);

  const escrow = m.contract("Escrow", [beneficiary, arbiter], {
    value: 1000000000000000000n, // 1 ETH in wei — must be > 0
    from: deployer,
  });

  return { escrow };
});