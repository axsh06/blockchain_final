import { useState } from 'react'
import { useAccount, useConnect, useDisconnect, useChainId, useSwitchChain, useReadContract, useWriteContract } from 'wagmi'
import { parseEther, formatEther } from 'viem'
import { arbitrumSepolia } from 'wagmi/chains'
import { CONTRACT_ADDRESSES } from './contracts'

import ammPairJson from './abis/AMMPair.json'
import yieldVaultJson from './abis/YieldVault.json'
import protocolGovernorJson from './abis/ProtocolGovernor.json'

function App() {
  const { address, isConnected } = useAccount()
  const { connectors, connect } = useConnect()
  const { disconnect } = useDisconnect()
  const chainId = useChainId()
  const { switchChain } = useSwitchChain()

  const [activeTab, setActiveTab] = useState('swap')
  const [swapAmount, setSwapAmount] = useState('')
  const [depositAmount, setDepositAmount] = useState('')

  const isWrongNetwork = isConnected && chainId !== arbitrumSepolia.id

  const { writeContract, isPending } = useWriteContract()

  const { data: vaultShares, refetch: refetchVault } = useReadContract({
    address: CONTRACT_ADDRESSES.YIELD_VAULT,
    abi: yieldVaultJson.abi,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  })

  const { data: votingPower } = useReadContract({
    address: CONTRACT_ADDRESSES.GOV_TOKEN,
    abi: protocolGovernorJson.abi,
    functionName: 'getVotes',
    args: address ? [address] : undefined,
  })

  const handleSwap = () => {
    if (!swapAmount) return
    writeContract({
      address: CONTRACT_ADDRESSES.AMM_PAIR,
      abi: ammPairJson.abi,
      functionName: 'swap',
      args: [parseEther(swapAmount), address],
    })
  }

  const handleDeposit = () => {
    if (!depositAmount) return
    writeContract({
      address: CONTRACT_ADDRESSES.YIELD_VAULT,
      abi: yieldVaultJson.abi,
      functionName: 'deposit',
      args: [parseEther(depositAmount), address],
    }, {
      onSuccess: () => refetchVault()
    })
  }

  const handleVote = (proposalId: string, support: number) => {
    writeContract({
      address: CONTRACT_ADDRESSES.PROTOCOL_GOVERNOR,
      abi: protocolGovernorJson.abi,
      functionName: 'castVote',
      args: [BigInt(proposalId), support],
    })
  }

  return (
    <div className="min-h-screen flex flex-col items-center py-12 px-4">
      <div className="max-w-2xl w-full border border-gray-900 p-8 rounded-lg text-center bg-black">
        
        <div className="flex justify-between items-center mb-8 border-b border-gray-800 pb-4">
          <h1 className="text-2xl font-bold tracking-widest uppercase">DeFi Protocol</h1>
          {isConnected && (
            <button
              onClick={() => disconnect()}
              className="text-xs text-gray-400 hover:text-white transition-colors border border-gray-800 px-3 py-1 rounded"
            >
              Disconnect {address?.slice(0, 6)}...{address?.slice(-4)}
            </button>
          )}
        </div>

        {!isConnected ? (
          <div className="max-w-sm mx-auto">
            <p className="text-gray-400 mb-6">Connect your wallet to access the decentralized protocol.</p>
            {connectors.map((connector) => (
              <button
                key={connector.uid}
                onClick={() => connect({ connector })}
                className="w-full bg-white text-black font-bold py-3 px-4 rounded hover:bg-gray-100 transition-colors"
              >
                Connect {connector.name}
              </button>
            ))}
          </div>
        ) : isWrongNetwork ? (
          <div className="max-w-sm mx-auto mb-6 border border-gray-800 p-4 rounded">
            <p className="text-white mb-4 font-bold">Wrong Network Detected</p>
            <button
              onClick={() => switchChain({ chainId: arbitrumSepolia.id })}
              className="w-full border border-white text-white font-bold py-3 px-4 rounded hover:bg-white hover:text-black transition-colors"
            >
              Switch to Arbitrum Sepolia
            </button>
          </div>
        ) : (
          <div>
            <div className="flex justify-center space-x-4 mb-8">
              {['swap', 'vault', 'dao'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-6 py-2 rounded font-bold uppercase tracking-wide text-sm transition-colors ${
                    activeTab === tab ? 'bg-white text-black' : 'border border-gray-800 text-gray-400 hover:border-gray-600'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>

            <div className="text-left">
              
              {activeTab === 'swap' && (
                <div className="max-w-sm mx-auto border border-gray-800 rounded-lg p-6 bg-[#050505]">
                  <h2 className="text-lg font-bold mb-4">Swap Tokens</h2>
                  <div className="mb-4">
                    <label className="text-xs text-gray-400 mb-1 block">Amount In</label>
                    <input 
                      type="number" 
                      placeholder="0.0" 
                      value={swapAmount}
                      onChange={(e) => setSwapAmount(e.target.value)}
                      className="w-full bg-black border border-gray-800 rounded p-3 text-white outline-none focus:border-gray-500"
                    />
                  </div>
                  <button 
                    onClick={handleSwap}
                    disabled={isPending}
                    className="w-full bg-white text-black font-bold py-3 rounded hover:bg-gray-200 transition-colors disabled:opacity-50"
                  >
                    {isPending ? 'Processing...' : 'Execute Swap'}
                  </button>
                </div>
              )}

              {activeTab === 'vault' && (
                <div className="max-w-sm mx-auto border border-gray-800 rounded-lg p-6 bg-[#050505]">
                  <div className="flex justify-between items-center mb-6 border-b border-gray-800 pb-4">
                    <h2 className="text-lg font-bold">ERC-4626 Vault</h2>
                    <div className="text-right">
                      <p className="text-xs text-gray-500">Your Shares</p>
                      <p className="font-mono font-bold text-white">
                        {vaultShares ? parseFloat(formatEther(vaultShares as bigint)).toFixed(4) : '0.0000'} vTKN
                      </p>
                    </div>
                  </div>
                  <div className="mb-6">
                    <label className="text-xs text-gray-400 mb-1 block">Amount to Deposit / Withdraw</label>
                    <input 
                      type="number" 
                      placeholder="0.0" 
                      value={depositAmount}
                      onChange={(e) => setDepositAmount(e.target.value)}
                      className="w-full bg-black border border-gray-800 rounded p-3 text-white outline-none focus:border-gray-500"
                    />
                  </div>
                  <button 
                    onClick={handleDeposit}
                    disabled={isPending}
                    className="w-full border border-white text-white font-bold py-3 rounded hover:bg-white hover:text-black transition-colors disabled:opacity-50"
                  >
                    {isPending ? 'Processing...' : 'Deposit to Vault'}
                  </button>
                </div>
              )}

              {activeTab === 'dao' && (
                <div className="border border-gray-800 rounded-lg p-6 bg-[#050505]">
                  <div className="flex justify-between items-center mb-6">
                    <h2 className="text-lg font-bold">Active Proposals</h2>
                    <div className="bg-gray-900 border border-gray-800 px-3 py-1 rounded text-sm">
                      Voting Power: <span className="font-bold text-white">
                        {votingPower ? parseFloat(formatEther(votingPower as bigint)).toFixed(2) : '0.00'} GOV
                      </span>
                    </div>
                  </div>

                  <div className="border border-gray-800 rounded p-4 mb-4">
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="font-bold text-white">Proposal #1: Change Pool Fee Parameter</h3>
                      <span className="bg-white text-black text-xs font-bold px-2 py-1 rounded uppercase">Active</span>
                    </div>
                    <p className="text-sm text-gray-400 mb-4">This proposal executes parameter updates via Timelock Controller.</p>
                    <div className="flex space-x-2">
                      <button onClick={() => handleVote('1', 1)} className="flex-1 border border-gray-700 hover:border-white text-white text-sm py-2 rounded">
                        Vote FOR
                      </button>
                      <button onClick={() => handleVote('1', 0)} className="flex-1 border border-gray-700 hover:border-white text-white text-sm py-2 rounded">
                        Vote AGAINST
                      </button>
                    </div>
                  </div>
                </div>
              )}

            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default App