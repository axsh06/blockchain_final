import { useState } from 'react'
import { useAccount, useConnect, useDisconnect, useChainId, useSwitchChain } from 'wagmi'
import { arbitrumSepolia } from 'wagmi/chains'

function App() {
  const { address, isConnected } = useAccount()
  const { connectors, connect } = useConnect()
  const { disconnect } = useDisconnect()
  const chainId = useChainId()
  const { switchChain } = useSwitchChain()

  const [activeTab, setActiveTab] = useState('swap')
  
  // Временные состояния для полей ввода (завтра привяжем к контрактам)
  const [swapAmount, setSwapAmount] = useState('')
  const [depositAmount, setDepositAmount] = useState('')

  const isWrongNetwork = isConnected && chainId !== arbitrumSepolia.id

  return (
    <div className="min-h-screen flex flex-col items-center py-12 px-4">
      <div className="max-w-2xl w-full border border-gray-900 p-8 rounded-lg text-center bg-black">
        {/* Шапка */}
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
            {/* Навигация */}
            <div className="flex justify-center space-x-4 mb-8">
              {['swap', 'vault', 'dao'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-6 py-2 rounded font-bold uppercase tracking-wide text-sm transition-colors ${
                    activeTab === tab
                      ? 'bg-white text-black'
                      : 'border border-gray-800 text-gray-400 hover:border-gray-600'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>

            {/* Контент вкладок */}
            <div className="text-left">
              
              {/* --- ВКЛАДКА 1: AMM SWAP --- */}
              {activeTab === 'swap' && (
                <div className="max-w-sm mx-auto border border-gray-800 rounded-lg p-6 bg-[#050505]">
                  <div className="flex justify-between items-center mb-4">
                    <h2 className="text-lg font-bold">Swap Tokens</h2>
                    <span className="text-xs text-gray-500">Slippage: 0.5%</span>
                  </div>
                  
                  <div className="mb-2">
                    <label className="text-xs text-gray-400 mb-1 block">You Pay (Token A)</label>
                    <input 
                      type="number" 
                      placeholder="0.0" 
                      value={swapAmount}
                      onChange={(e) => setSwapAmount(e.target.value)}
                      className="w-full bg-black border border-gray-800 rounded p-3 text-white outline-none focus:border-gray-500 transition-colors"
                    />
                  </div>
                  
                  <div className="flex justify-center my-2 text-gray-600">
                    ↓
                  </div>

                  <div className="mb-6">
                    <label className="text-xs text-gray-400 mb-1 block">You Receive (Token B)</label>
                    <input 
                      type="number" 
                      placeholder="0.0" 
                      disabled
                      className="w-full bg-black border border-gray-800 rounded p-3 text-gray-500 outline-none cursor-not-allowed"
                    />
                  </div>

                  {/* ЗАВТРА: Привяжем сюда функцию writeContract для обмена */}
                  <button className="w-full bg-white text-black font-bold py-3 rounded hover:bg-gray-200 transition-colors">
                    Execute Swap
                  </button>
                  <p className="text-center text-xs text-gray-600 mt-3">Pool Fee: 0.3%</p>
                </div>
              )}

              {/* --- ВКЛАДКА 2: YIELD VAULT --- */}
              {activeTab === 'vault' && (
                <div className="max-w-sm mx-auto border border-gray-800 rounded-lg p-6 bg-[#050505]">
                  <div className="flex justify-between items-center mb-6 border-b border-gray-800 pb-4">
                    <h2 className="text-lg font-bold">ERC-4626 Vault</h2>
                    <div className="text-right">
                      <p className="text-xs text-gray-500">Your Shares</p>
                      <p className="font-mono font-bold">0.00 vTKN</p>
                    </div>
                  </div>

                  <div className="mb-6">
                    <label className="text-xs text-gray-400 mb-1 block">Amount to Deposit / Withdraw</label>
                    <input 
                      type="number" 
                      placeholder="0.0" 
                      value={depositAmount}
                      onChange={(e) => setDepositAmount(e.target.value)}
                      className="w-full bg-black border border-gray-800 rounded p-3 text-white outline-none focus:border-gray-500 transition-colors"
                    />
                  </div>

                  <div className="flex space-x-3">
                    {/* ЗАВТРА: Привяжем вызов deposit() */}
                    <button className="w-1/2 border border-white text-white font-bold py-2 rounded hover:bg-white hover:text-black transition-colors">
                      Deposit
                    </button>
                    {/* ЗАВТРА: Привяжем вызов withdraw() или redeem() */}
                    <button className="w-1/2 border border-gray-800 text-gray-400 font-bold py-2 rounded hover:border-gray-500 transition-colors">
                      Withdraw
                    </button>
                  </div>
                </div>
              )}

              {/* --- ВКЛАДКА 3: DAO GOVERNANCE --- */}
              {activeTab === 'dao' && (
                <div className="border border-gray-800 rounded-lg p-6 bg-[#050505]">
                  <div className="flex justify-between items-center mb-6">
                    <h2 className="text-lg font-bold">Active Proposals</h2>
                    <div className="bg-gray-900 border border-gray-800 px-3 py-1 rounded text-sm">
                      Voting Power: <span className="font-bold text-white">0.00 GOV</span>
                    </div>
                  </div>

                  {/* Карточка пропоузала (заглушка) */}
                  <div className="border border-gray-800 rounded p-4 mb-4">
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="font-bold text-white">Proposal #1: Change Pool Fee to 0.5%</h3>
                      <span className="bg-white text-black text-xs font-bold px-2 py-1 rounded uppercase tracking-wide">
                        Active
                      </span>
                    </div>
                    <p className="text-sm text-gray-400 mb-4">
                      This proposal updates the AMM pool fee parameter via the Timelock controller.
                    </p>
                    
                    <div className="flex space-x-2">
                      {/* ЗАВТРА: Привяжем функцию castVote(proposalId, support) */}
                      <button className="flex-1 border border-gray-700 hover:border-white text-white text-sm py-2 rounded transition-colors">
                        Vote FOR
                      </button>
                      <button className="flex-1 border border-gray-700 hover:border-white text-white text-sm py-2 rounded transition-colors">
                        Vote AGAINST
                      </button>
                    </div>
                  </div>

                  <div className="text-center mt-6">
                    <p className="text-xs text-gray-600">More proposals will appear here via The Graph indexer.</p>
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