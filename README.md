# 🛡️ Trade Escrow Smart Contract

## 📖 Overview
This project is a **decentralized, trustless escrow system** built as a single, self-contained smart contract on the **Ethereum blockchain**.  
It facilitates secure **peer-to-peer (P2P) trades** by acting as a neutral third party, holding funds in escrow until both the buyer and seller fulfill their agreed-upon conditions.  

The system’s architecture is based on a **state machine pattern**, ensuring all transactions follow a strict, logical sequence.

<img width="3840" height="3713" alt="Mermaid Chart - Create complex, visual diagrams with text  A smarter way of creating diagrams -2025-08-31-182910" src="https://github.com/user-attachments/assets/ced4ac62-0f7c-4693-a2cb-a1fb033d3904" />

---

## ✨ Core Features
- **Trustless Transactions**: The contract itself acts as the escrow agent, removing the need for intermediaries.  
- **State Machine Pattern**: Enforces a strict progression of states (`PaymentHeld → Shipped → Disputed`), preventing unauthorized or out-of-order calls.  
- **Dispute Resolution**: A designated arbiter resolves disputes and fairly releases funds.  
- **Document Verification**: Supports off-chain document hashes (e.g., bill of lading) for trust and traceability.  

---

## 👥 Roles
- **Buyer**  
  - Initiates the trade and deposits funds into escrow.  
  - Can confirm delivery or cancel the trade before shipment.  

- **Seller**  
  - Receives funds upon successful completion.  
  - Responsible for setting document hashes and marking the item as shipped.  

- **Verifier**  
  - Confirms the authenticity of a document hash.  

- **Arbiter**  
  - Neutral third party to resolve disputes.  

---

## ⚙️ Functions
### 🔑 Trade Lifecycle
- **`createTrade`** → Initiates a new trade, moving funds into escrow.  
- **`markShipped`** → Seller signals that the item has been shipped.  
- **`confirmDelivered`** → Buyer confirms receipt of the item.  

### 📑 Document Handling
- **`setExpectedDocumentHash`** → Sets a document hash for verification.  
- **`verifyDocument`** → Verifier confirms document authenticity.  

### ⚖️ Dispute Management
- **`raiseDispute`** → Buyer or seller initiates a dispute.  
- **`resolveDispute`** → Arbiter resolves the dispute and releases funds.  

### ❌ Cancellation
- **`cancelBeforeShipment`** → Buyer cancels trade and receives a refund (only before shipment).  

---

## 🚀 Tech Stack
- **Ethereum Blockchain** (Solidity)  
- **State Machine Architecture**  
- **Off-chain Document Hashing**  

---

## 📌 Notes
This contract provides a **secure, transparent, and decentralized escrow solution**, ideal for **trade finance and P2P marketplaces**.  
It ensures trust between parties while maintaining flexibility through dispute resolution and document verification.
