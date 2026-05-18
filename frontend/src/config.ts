import { http, createConfig } from "wagmi";
import { arbitrumSepolia } from "wagmi/chains";
import { injected } from "wagmi/connectors";

export const config = createConfig({
  chains: [arbitrumSepolia] as const,
  connectors: [injected({ target: "metaMask" })],
  transports: {
    [arbitrumSepolia.id]: http(),
  },
});
