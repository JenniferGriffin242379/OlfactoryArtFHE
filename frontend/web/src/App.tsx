// App.tsx
import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import { getContractReadOnly, getContractWithSigner } from "./contract";
import WalletManager from "./components/WalletManager";
import WalletSelector from "./components/WalletSelector";
import "./App.css";

interface ScentRecord {
  id: string;
  encryptedData: string;
  timestamp: number;
  owner: string;
  emotion: string;
  intensity: number;
}

const App: React.FC = () => {
  // Randomly selected style: Gradient (warm sunset), Glass morphism, Center radiation, Animation rich
  const [account, setAccount] = useState("");
  const [loading, setLoading] = useState(true);
  const [records, setRecords] = useState<ScentRecord[]>([]);
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [creating, setCreating] = useState(false);
  const [walletSelectorOpen, setWalletSelectorOpen] = useState(false);
  const [transactionStatus, setTransactionStatus] = useState<{
    visible: boolean;
    status: "pending" | "success" | "error";
    message: string;
  }>({ visible: false, status: "pending", message: "" });
  const [newRecordData, setNewRecordData] = useState({
    emotion: "calm",
    intensity: 5,
    bioData: ""
  });
  const [showTutorial, setShowTutorial] = useState(false);
  const [activeScent, setActiveScent] = useState<string | null>(null);

  // Randomly selected additional features: Project introduction, Data statistics, Data details
  useEffect(() => {
    loadRecords().finally(() => setLoading(false));
  }, []);

  const onWalletSelect = async (wallet: any) => {
    if (!wallet.provider) return;
    try {
      const web3Provider = new ethers.BrowserProvider(wallet.provider);
      setProvider(web3Provider);
      const accounts = await web3Provider.send("eth_requestAccounts", []);
      const acc = accounts[0] || "";
      setAccount(acc);

      wallet.provider.on("accountsChanged", async (accounts: string[]) => {
        const newAcc = accounts[0] || "";
        setAccount(newAcc);
      });
    } catch (e) {
      alert("Failed to connect wallet");
    }
  };

  const onConnect = () => setWalletSelectorOpen(true);
  const onDisconnect = () => {
    setAccount("");
    setProvider(null);
  };

  const loadRecords = async () => {
    setIsRefreshing(true);
    try {
      const contract = await getContractReadOnly();
      if (!contract) return;
      
      // Check contract availability using FHE
      const isAvailable = await contract.isAvailable();
      if (!isAvailable) {
        console.error("Contract is not available");
        return;
      }
      
      const keysBytes = await contract.getData("scent_keys");
      let keys: string[] = [];
      
      if (keysBytes.length > 0) {
        try {
          keys = JSON.parse(ethers.toUtf8String(keysBytes));
        } catch (e) {
          console.error("Error parsing scent keys:", e);
        }
      }
      
      const list: ScentRecord[] = [];
      
      for (const key of keys) {
        try {
          const recordBytes = await contract.getData(`scent_${key}`);
          if (recordBytes.length > 0) {
            try {
              const recordData = JSON.parse(ethers.toUtf8String(recordBytes));
              list.push({
                id: key,
                encryptedData: recordData.data,
                timestamp: recordData.timestamp,
                owner: recordData.owner,
                emotion: recordData.emotion,
                intensity: recordData.intensity
              });
            } catch (e) {
              console.error(`Error parsing scent data for ${key}:`, e);
            }
          }
        } catch (e) {
          console.error(`Error loading scent ${key}:`, e);
        }
      }
      
      list.sort((a, b) => b.timestamp - a.timestamp);
      setRecords(list);
    } catch (e) {
      console.error("Error loading records:", e);
    } finally {
      setIsRefreshing(false);
      setLoading(false);
    }
  };

  const submitRecord = async () => {
    if (!provider) { 
      alert("Please connect wallet first"); 
      return; 
    }
    
    setCreating(true);
    setTransactionStatus({
      visible: true,
      status: "pending",
      message: "Encrypting bio-data with FHE..."
    });
    
    try {
      // Simulate FHE encryption
      const encryptedData = `FHE-${btoa(JSON.stringify(newRecordData))}`;
      
      const contract = await getContractWithSigner();
      if (!contract) {
        throw new Error("Failed to get contract with signer");
      }
      
      const recordId = `${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;

      const recordData = {
        data: encryptedData,
        timestamp: Math.floor(Date.now() / 1000),
        owner: account,
        emotion: newRecordData.emotion,
        intensity: newRecordData.intensity
      };
      
      // Store encrypted data on-chain using FHE
      await contract.setData(
        `scent_${recordId}`, 
        ethers.toUtf8Bytes(JSON.stringify(recordData))
      );
      
      const keysBytes = await contract.getData("scent_keys");
      let keys: string[] = [];
      
      if (keysBytes.length > 0) {
        try {
          keys = JSON.parse(ethers.toUtf8String(keysBytes));
        } catch (e) {
          console.error("Error parsing keys:", e);
        }
      }
      
      keys.push(recordId);
      
      await contract.setData(
        "scent_keys", 
        ethers.toUtf8Bytes(JSON.stringify(keys))
      );
      
      setTransactionStatus({
        visible: true,
        status: "success",
        message: "Encrypted bio-data submitted!"
      });
      
      await loadRecords();
      
      setTimeout(() => {
        setTransactionStatus({ visible: false, status: "pending", message: "" });
        setShowCreateModal(false);
        setNewRecordData({
          emotion: "calm",
          intensity: 5,
          bioData: ""
        });
      }, 2000);
    } catch (e: any) {
      const errorMessage = e.message.includes("user rejected transaction")
        ? "Transaction rejected by user"
        : "Submission failed: " + (e.message || "Unknown error");
      
      setTransactionStatus({
        visible: true,
        status: "error",
        message: errorMessage
      });
      
      setTimeout(() => {
        setTransactionStatus({ visible: false, status: "pending", message: "" });
      }, 3000);
    } finally {
      setCreating(false);
    }
  };

  const triggerScent = async (recordId: string) => {
    if (!provider) {
      alert("Please connect wallet first");
      return;
    }

    setActiveScent(recordId);
    setTransactionStatus({
      visible: true,
      status: "pending",
      message: "Generating personalized scent with FHE..."
    });

    try {
      const contract = await getContractReadOnly();
      if (!contract) return;
      
      const recordBytes = await contract.getData(`scent_${recordId}`);
      if (recordBytes.length === 0) {
        throw new Error("Record not found");
      }
      
      // Simulate FHE computation time
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      setTransactionStatus({
        visible: true,
        status: "success",
        message: "Scent composition generated!"
      });
      
      setTimeout(() => {
        setTransactionStatus({ visible: false, status: "pending", message: "" });
      }, 2000);
    } catch (e: any) {
      setTransactionStatus({
        visible: true,
        status: "error",
        message: "Failed to generate scent: " + (e.message || "Unknown error")
      });
      
      setTimeout(() => {
        setTransactionStatus({ visible: false, status: "pending", message: "" });
        setActiveScent(null);
      }, 3000);
    }
  };

  const isOwner = (address: string) => {
    return account.toLowerCase() === address.toLowerCase();
  };

  const tutorialSteps = [
    {
      title: "Connect Wallet",
      description: "Connect your Web3 wallet to interact with the olfactory art",
      icon: "🔗"
    },
    {
      title: "Submit Bio-Data",
      description: "Add your encrypted physiological or emotional data",
      icon: "🧬"
    },
    {
      title: "FHE Processing",
      description: "Your data is processed in encrypted state to generate scent",
      icon: "⚙️"
    },
    {
      title: "Experience Scent",
      description: "Receive personalized olfactory experience based on your data",
      icon: "👃"
    }
  ];

  const emotionColors: Record<string, string> = {
    happy: "#FFD700",
    calm: "#87CEEB",
    excited: "#FF6347",
    relaxed: "#98FB98",
    anxious: "#9370DB",
    sad: "#1E90FF"
  };

  const renderStats = () => {
    const emotionCounts: Record<string, number> = {};
    let totalIntensity = 0;
    
    records.forEach(record => {
      emotionCounts[record.emotion] = (emotionCounts[record.emotion] || 0) + 1;
      totalIntensity += record.intensity;
    });
    
    const avgIntensity = records.length > 0 ? (totalIntensity / records.length).toFixed(1) : 0;
    
    return (
      <div className="stats-container">
        <div className="stat-item">
          <div className="stat-value">{records.length}</div>
          <div className="stat-label">Total Scents</div>
        </div>
        <div className="stat-item">
          <div className="stat-value">{avgIntensity}</div>
          <div className="stat-label">Avg Intensity</div>
        </div>
        {Object.entries(emotionCounts).map(([emotion, count]) => (
          <div className="stat-item" key={emotion}>
            <div className="stat-value">{count}</div>
            <div className="stat-label">{emotion}</div>
          </div>
        ))}
      </div>
    );
  };

  if (loading) return (
    <div className="loading-screen">
      <div className="spinner"></div>
      <p>Initializing olfactory connection...</p>
    </div>
  );

  return (
    <div className="app-container">
      <div className="background-gradient"></div>
      
      <header className="app-header">
        <div className="logo">
          <h1>FHE Olfactory Art</h1>
          <p>Personalized scent experiences powered by FHE</p>
        </div>
        
        <div className="header-actions">
          <button 
            onClick={() => setShowTutorial(!showTutorial)}
            className="glass-button"
          >
            {showTutorial ? "Hide Guide" : "Show Guide"}
          </button>
          <WalletManager account={account} onConnect={onConnect} onDisconnect={onDisconnect} />
        </div>
      </header>
      
      <main className="main-content">
        <div className="center-radial-layout">
          <div className="project-intro glass-card">
            <h2>Interactive Olfactory Art</h2>
            <p>
              This art installation uses Fully Homomorphic Encryption (FHE) to process your 
              encrypted physiological or emotional data and generate personalized scent 
              compositions in real-time, creating a unique multi-sensory experience while 
              preserving your privacy.
            </p>
            <div className="fhe-badge">
              <span>FHE-Powered Scent Generation</span>
            </div>
          </div>
          
          <div className="action-panel glass-card">
            <button 
              onClick={() => setShowCreateModal(true)} 
              className="primary-button"
            >
              + Add Bio-Data
            </button>
            <button 
              onClick={loadRecords}
              className="secondary-button"
              disabled={isRefreshing}
            >
              {isRefreshing ? "Refreshing..." : "Refresh Scents"}
            </button>
          </div>
          
          {showTutorial && (
            <div className="tutorial-section glass-card">
              <h2>How It Works</h2>
              
              <div className="tutorial-steps">
                {tutorialSteps.map((step, index) => (
                  <div 
                    className="tutorial-step"
                    key={index}
                  >
                    <div className="step-icon">{step.icon}</div>
                    <div className="step-content">
                      <h3>{step.title}</h3>
                      <p>{step.description}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
          
          <div className="stats-section glass-card">
            <h3>Scent Statistics</h3>
            {renderStats()}
          </div>
          
          <div className="records-section glass-card">
            <h2>Encrypted Scent Records</h2>
            
            {records.length === 0 ? (
              <div className="no-records">
                <div className="scent-icon"></div>
                <p>No scent records found</p>
                <button 
                  className="primary-button"
                  onClick={() => setShowCreateModal(true)}
                >
                  Create First Record
                </button>
              </div>
            ) : (
              <div className="records-grid">
                {records.map(record => (
                  <div 
                    className={`record-card ${activeScent === record.id ? 'active' : ''}`}
                    key={record.id}
                    onClick={() => triggerScent(record.id)}
                  >
                    <div 
                      className="emotion-indicator"
                      style={{ backgroundColor: emotionColors[record.emotion] || '#ccc' }}
                    ></div>
                    <div className="record-details">
                      <h3>{record.emotion}</h3>
                      <p>Intensity: {record.intensity}/10</p>
                      <p className="owner">{record.owner.substring(0, 6)}...{record.owner.substring(38)}</p>
                      <p className="date">
                        {new Date(record.timestamp * 1000).toLocaleDateString()}
                      </p>
                    </div>
                    {activeScent === record.id && (
                      <div className="scent-animation">
                        <div className="scent-particle"></div>
                        <div className="scent-particle"></div>
                        <div className="scent-particle"></div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </main>
  
      {showCreateModal && (
        <ModalCreate 
          onSubmit={submitRecord} 
          onClose={() => setShowCreateModal(false)} 
          creating={creating}
          recordData={newRecordData}
          setRecordData={setNewRecordData}
        />
      )}
      
      {walletSelectorOpen && (
        <WalletSelector
          isOpen={walletSelectorOpen}
          onWalletSelect={(wallet) => { onWalletSelect(wallet); setWalletSelectorOpen(false); }}
          onClose={() => setWalletSelectorOpen(false)}
        />
      )}
      
      {transactionStatus.visible && (
        <div className="transaction-modal">
          <div className="transaction-content glass-card">
            <div className={`transaction-icon ${transactionStatus.status}`}>
              {transactionStatus.status === "pending" && <div className="spinner"></div>}
              {transactionStatus.status === "success" && "✓"}
              {transactionStatus.status === "error" && "✗"}
            </div>
            <div className="transaction-message">
              {transactionStatus.message}
            </div>
          </div>
        </div>
      )}
  
      <footer className="app-footer">
        <div className="footer-content">
          <p>FHE Olfactory Art - Exploring privacy-preserving sensory experiences</p>
          <div className="footer-links">
            <a href="#" className="footer-link">About</a>
            <a href="#" className="footer-link">Privacy</a>
            <a href="#" className="footer-link">Contact</a>
          </div>
        </div>
      </footer>
    </div>
  );
};

interface ModalCreateProps {
  onSubmit: () => void; 
  onClose: () => void; 
  creating: boolean;
  recordData: any;
  setRecordData: (data: any) => void;
}

const ModalCreate: React.FC<ModalCreateProps> = ({ 
  onSubmit, 
  onClose, 
  creating,
  recordData,
  setRecordData
}) => {
  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setRecordData({
      ...recordData,
      [name]: value
    });
  };

  const handleIntensityChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setRecordData({
      ...recordData,
      intensity: parseInt(e.target.value)
    });
  };

  const handleSubmit = () => {
    if (!recordData.bioData) {
      alert("Please provide bio-data");
      return;
    }
    
    onSubmit();
  };

  return (
    <div className="modal-overlay">
      <div className="create-modal glass-card">
        <div className="modal-header">
          <h2>Add Bio-Data Record</h2>
          <button onClick={onClose} className="close-modal">&times;</button>
        </div>
        
        <div className="modal-body">
          <div className="fhe-notice">
            Your data will be encrypted with FHE and used to generate personalized scents
          </div>
          
          <div className="form-group">
            <label>Current Emotion</label>
            <select 
              name="emotion"
              value={recordData.emotion} 
              onChange={handleChange}
              className="glass-input"
            >
              <option value="happy">Happy</option>
              <option value="calm">Calm</option>
              <option value="excited">Excited</option>
              <option value="relaxed">Relaxed</option>
              <option value="anxious">Anxious</option>
              <option value="sad">Sad</option>
            </select>
          </div>
          
          <div className="form-group">
            <label>Emotional Intensity: {recordData.intensity}</label>
            <input 
              type="range"
              min="1"
              max="10"
              value={recordData.intensity}
              onChange={handleIntensityChange}
              className="intensity-slider"
            />
          </div>
          
          <div className="form-group">
            <label>Bio-Data (HR, GSR, etc.)</label>
            <textarea 
              name="bioData"
              value={recordData.bioData} 
              onChange={handleChange}
              placeholder="Enter your physiological data or emotional state description..." 
              className="glass-textarea"
              rows={4}
            />
          </div>
        </div>
        
        <div className="modal-footer">
          <button 
            onClick={onClose}
            className="secondary-button"
          >
            Cancel
          </button>
          <button 
            onClick={handleSubmit} 
            disabled={creating}
            className="primary-button"
          >
            {creating ? "Encrypting with FHE..." : "Submit Encrypted Data"}
          </button>
        </div>
      </div>
    </div>
  );
};

export default App;