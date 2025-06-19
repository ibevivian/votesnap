;; Snapshot Voting Smart Contract
;; A decentralized voting system that captures token balances at specific block heights

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u101))
(define-constant ERR-VOTING-ENDED (err u102))
(define-constant ERR-VOTING-NOT-STARTED (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-SNAPSHOT (err u106))
(define-constant ERR-PROPOSAL-EXISTS (err u107))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Proposal structure
(define-map proposals
  { proposal-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    snapshot-block: uint,
    start-block: uint,
    end-block: uint,
    yes-votes: uint,
    no-votes: uint,
    total-votes: uint,
    is-active: bool
  }
)

;; Vote records - tracks who voted on which proposal
(define-map votes
  { proposal-id: uint, voter: principal }
  {
    vote: bool, ;; true for yes, false for no
    voting-power: uint,
    block-height: uint
  }
)

;; Voter balances at snapshot - stores token balance at specific block
(define-map snapshot-balances
  { proposal-id: uint, voter: principal }
  { balance: uint }
)

;; Counter for proposal IDs
(define-data-var proposal-counter uint u0)

;; Minimum voting power required
(define-data-var min-voting-power uint u1)

;; Token contract for balance checking (can be updated by owner)
(define-data-var token-contract principal 'SP000000000000000000002Q6VF78)

;; Read-only functions

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals { proposal-id: proposal-id })
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? votes { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-snapshot-balance (proposal-id uint) (voter principal))
  (map-get? snapshot-balances { proposal-id: proposal-id, voter: voter })
)

(define-read-only (get-proposal-counter)
  (var-get proposal-counter)
)

(define-read-only (get-min-voting-power)
  (var-get min-voting-power)
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (is-some (map-get? votes { proposal-id: proposal-id, voter: voter }))
)

(define-read-only (is-voting-active (proposal-id uint))
  (match (get-proposal proposal-id)
    proposal (and 
               (get is-active proposal)
               (>= block-height (get start-block proposal))
               (<= block-height (get end-block proposal)))
    false
  )
)

(define-read-only (get-proposal-results (proposal-id uint))
  (match (get-proposal proposal-id)
    proposal {
      yes-votes: (get yes-votes proposal),
      no-votes: (get no-votes proposal),
      total-votes: (get total-votes proposal),
      participation-rate: (if (> (get total-votes proposal) u0)
                           (/ (* (get total-votes proposal) u10000) 
                              (+ (get yes-votes proposal) (get no-votes proposal)))
                           u0)
    }
    { yes-votes: u0, no-votes: u0, total-votes: u0, participation-rate: u0 }
  )
)

;; Private functions

(define-private (get-token-balance-at-block (account principal) (block-height uint))
  ;; In a real implementation, this would query historical token balances
  ;; For now, we'll use current balance as placeholder
  ;; This should be replaced with actual historical balance lookup
  (contract-call? .sample-token get-balance account)
)

;; Public functions

;; Create a new proposal
(define-public (create-proposal 
  (title (string-ascii 100))
  (description (string-ascii 500))
  (voting-duration uint)
  (voting-delay uint))
  (let (
    (proposal-id (+ (var-get proposal-counter) u1))
    (snapshot-block block-height)
    (start-block (+ block-height voting-delay))
    (end-block (+ block-height voting-delay voting-duration))
  )
    ;; Check if proposal with same title exists
    (asserts! (is-none (map-get? proposals { proposal-id: proposal-id })) ERR-PROPOSAL-EXISTS)
    
    ;; Create the proposal
    (map-set proposals
      { proposal-id: proposal-id }
      {
        title: title,
        description: description,
        creator: tx-sender,
        snapshot-block: snapshot-block,
        start-block: start-block,
        end-block: end-block,
        yes-votes: u0,
        no-votes: u0,
        total-votes: u0,
        is-active: true
      }
    )
    
    ;; Increment counter
    (var-set proposal-counter proposal-id)
    
    (ok proposal-id)
  )
)

;; Record snapshot balance for a voter
(define-public (record-snapshot-balance (proposal-id uint) (voter principal))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
    (balance (unwrap-panic (get-token-balance-at-block voter (get snapshot-block proposal))))
  )
    ;; Only allow recording if balance meets minimum requirement
    (asserts! (>= balance (var-get min-voting-power)) ERR-INSUFFICIENT-BALANCE)
    
    ;; Record the snapshot balance
    (map-set snapshot-balances
      { proposal-id: proposal-id, voter: voter }
      { balance: balance }
    )
    
    (ok balance)
  )
)

;; Cast a vote
(define-public (cast-vote (proposal-id uint) (vote bool))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
    (voter-balance (unwrap! (get-snapshot-balance proposal-id tx-sender) ERR-INVALID-SNAPSHOT))
    (voting-power (get balance voter-balance))
  )
    ;; Check if voting is active
    (asserts! (is-voting-active proposal-id) ERR-VOTING-NOT-STARTED)
    
    ;; Check if user hasn't already voted
    (asserts! (not (has-voted proposal-id tx-sender)) ERR-ALREADY-VOTED)
    
    ;; Check if user has sufficient voting power
    (asserts! (>= voting-power (var-get min-voting-power)) ERR-INSUFFICIENT-BALANCE)
    
    ;; Record the vote
    (map-set votes
      { proposal-id: proposal-id, voter: tx-sender }
      {
        vote: vote,
        voting-power: voting-power,
        block-height: block-height
      }
    )
    
    ;; Update proposal vote counts
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal {
        yes-votes: (if vote 
                     (+ (get yes-votes proposal) voting-power)
                     (get yes-votes proposal)),
        no-votes: (if vote
                    (get no-votes proposal)
                    (+ (get no-votes proposal) voting-power)),
        total-votes: (+ (get total-votes proposal) voting-power)
      })
    )
    
    (ok voting-power)
  )
)

;; End a proposal (can be called by creator or contract owner)
(define-public (end-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
  )
    ;; Check authorization
    (asserts! (or (is-eq tx-sender (get creator proposal))
                  (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    
    ;; Deactivate the proposal
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { is-active: false })
    )
    
    (ok true)
  )
)

;; Admin functions (only contract owner)

(define-public (set-min-voting-power (new-min uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set min-voting-power new-min)
    (ok true)
  )
)

(define-public (set-token-contract (new-contract principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set token-contract new-contract)
    (ok true)
  )
)

;; Emergency function to deactivate any proposal
(define-public (emergency-deactivate (proposal-id uint))
  (let (
    (proposal (unwrap! (get-proposal proposal-id) ERR-PROPOSAL-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    (map-set proposals
      { proposal-id: proposal-id }
      (merge proposal { is-active: false })
    )
    
    (ok true)
  )
)