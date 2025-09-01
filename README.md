# 🛡️ Trade Escrow Smart Contract

Report: https://drive.google.com/file/d/1FohOgo6q0X7Ty73inyINrNfph8--czQV/view?usp=sharing

## 📖 Overview
# 🛡️ Escrow Smart Contract with Remix IDE

## 📌 Project Overview  

This project demonstrates a **Smart Contract-based Escrow System** built in **Solidity** and tested using **Remix IDE**.  
The contract facilitates secure transactions between a **buyer** and **seller** with the involvement of a **verifier** and an optional **arbiter** for dispute resolution.  

The repository contains:  
- ✅ **Complete Smart Contract Code** with inline explanations.  
- ✅ **Step-by-step deployment guide** using **Remix IDE**.  
- ✅ **Detailed walkthroughs of multiple scenarios**, including:  
  - Buyer purchasing an item and confirming delivery.  
  - Buyer canceling a trade before shipment.  
  - Dispute resolution with an arbiter deciding the outcome.  
- ✅ **Transaction flows** explained with clear states:  
  - `Created` → `Shipped` → `Completed`  
  - `Cancelled` (if buyer cancels before shipment)  
  - `Disputed` (with arbiter’s final decision)  
- ✅ **Sample trade examples** with ETH amounts for realistic testing.  

The contract is fully compatible with the **[Remix IDE](https://remix.ethereum.org/)**, making it easy to compile, deploy, and test directly in the browser.  

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

---

## 📚 Example Scenario 1: Phone Purchase (10 ETH)

This example walks through the full lifecycle of a successful trade using **Remix IDE**.

### **Step 1: Deploy the Contract**
- In Remix, open the **Deploy & Run Transactions** tab.  
- Select `TradeEscrow` in the **CONTRACT** dropdown.  
- Next to **Deploy**, enter the address of the arbiter (this can be an address you control).  
- Click **Deploy** and confirm the transaction in MetaMask.  
- Once mined, the contract will appear under **Deployed Contracts**.

---

### **Step 2: Buyer Creates the Trade**
- Expand the deployed contract interface.  
- Locate the **`createTrade`** function and provide:
  1. `seller`: The seller’s wallet address.  
  2. `verifier`: The verifier’s wallet address (can be seller or another account).  
  3. `details`: A string describing the trade (e.g., `"Phone purchase"`).  
- In the **Value** field (above the function list), enter `10` ETH.  
- Click **transact** and confirm in MetaMask.  
- A **trade ID** will be generated and displayed in the Remix terminal — save this for later steps.  

---

### **Step 3: Seller Sets the Document Hash**
- Switch to the **seller’s account** in MetaMask.  
- Call **`setExpectedDocumentHash`** with:
  1. `id`: The unique trade ID.  
  2. `expectedDocHash`: A `bytes32` hash of a shipment document.  
     - You can generate this by calling the contract’s `hashString` helper (e.g., input `"shipment123"` to get the hash).  
- Click **transact** and confirm.  

---

### **Step 4: Verifier Confirms the Document**
- Switch to the **verifier’s account**.  
- Call **`verifyDocument`** with:
  1. `id`: The trade ID.  
  2. `providedHash`: The same hash used in Step 3.  
- Click **transact**.  

---

### **Step 5: Seller Marks the Item as Shipped**
- Switch back to the **seller’s account**.  
- Call **`markShipped`** with the trade ID.  
- Confirm the transaction.  

---

### **Step 6: Buyer Confirms Delivery**
- Switch to the **buyer’s account**.  
- Call **`confirmDelivered`** with the trade ID.  
- Confirm the transaction in MetaMask.  

---

✅ At this point, the escrowed **10 ETH is released to the seller**, and the trade is marked as **Completed**.  
You can verify this by checking the seller’s wallet balance in MetaMask.  

---
---

## 📚 Example Scenario 2: Buyer Cancels Before Shipment (5 ETH)

This scenario tests the **`cancelBeforeShipment`** function, which allows the buyer to get a full refund if the seller has not yet shipped the item.

### **Step 1: Start a New Trade**
- Switch to the **buyer’s account** in MetaMask.  
- Call **`createTrade`** with:
  - `seller`: Seller’s wallet address.  
  - `verifier`: Verifier’s wallet address.  
  - `details`: Description of the item (e.g., `"Phone charger"`).  
- Enter **5 ETH** in the **Value** field.  
- Click **transact** and confirm.  
- Save the new **trade ID**.  

---

### **Step 2: Buyer Cancels**
- Before the seller calls any functions, locate **`cancelBeforeShipment`**.  
- Input the **trade ID** and click **transact**.  
- Confirm the transaction in MetaMask.  

---

✅ The escrowed **5 ETH is refunded to the buyer**, and the trade state is updated to **Cancelled**.  
The seller can no longer interact with this trade ID — attempting to do so will revert with a **“Bad state”** error.  

---

## 📚 Example Scenario 3: Dispute Raised and Resolved (7 ETH)

This scenario demonstrates how a neutral **arbiter** resolves conflicts between buyer and seller.

### **Step 1: Start a New Trade**
- Using the **buyer’s account**, call **`createTrade`** with:
  - `seller`: Seller’s wallet address.  
  - `verifier`: Verifier’s wallet address.  
  - `details`: `"Phone accessory"`.  
- Enter **7 ETH** in the **Value** field.  
- Save the **trade ID**.  

---

### **Step 2: Raise a Dispute**
- Either buyer or seller can raise a dispute.  
- For this example, the **buyer** raises it.  
- Call **`raiseDispute`** with:
  - `id`: The trade ID.  
  - `reason`: A string explaining the dispute (e.g., `"Item not received after 3 weeks"`).  
- Click **transact**.  
- The trade’s state changes to **Disputed**.  

---

### **Step 3: Arbiter Resolves**
- Switch to the **arbiter’s account** (the address defined at deployment).  
- Call **`resolveDispute`** with:
  - `id`: The trade ID.  
  - `releaseToSeller`: A boolean.  
    - `true` → release funds to **seller**.  
    - `false` → refund funds to **buyer**.  
- Click **transact** and confirm.  

---

✅ Funds are released according to the arbiter’s decision, and the trade is marked **Completed**.  
The arbiter’s judgment is **final** and permanently recorded on-chain.  

---


## 📌 Notes
This contract provides a **secure, transparent, and decentralized escrow solution**, ideal for **trade finance and P2P marketplaces**.  
It ensures trust between parties while maintaining flexibility through dispute resolution and document verification.
