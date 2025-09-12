
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ASSET_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_TOKENS (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_ASSET_NOT_VERIFIED (err u104))
(define-constant ERR_ALREADY_EXISTS (err u105))
(define-constant ERR_TRANSFER_FAILED (err u106))
(define-constant ERR_INVALID_PRICE (err u107))
(define-constant ERR_ASSET_EXPIRED (err u108))
(define-constant ERR_INVALID_EXPIRY (err u109))
(define-constant ERR_AUCTION_NOT_FOUND (err u110))
(define-constant ERR_AUCTION_ENDED (err u111))
(define-constant ERR_AUCTION_ACTIVE (err u112))
(define-constant ERR_INVALID_DURATION (err u113))
(define-constant ERR_INVALID_PRICE_DROP (err u114))

(define-data-var next-asset-id uint u1)
(define-data-var platform-fee uint u50)
(define-data-var next-auction-id uint u1)

(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    category: (string-ascii 20),
    total-tokens: uint,
    token-price: uint,
    verified: bool,
    oracle: (optional principal),
    created-at: uint,
    expires-at: (optional uint),
    renewable: bool
  }
)

(define-map asset-tokens
  { asset-id: uint, holder: principal }
  { amount: uint }
)

(define-map asset-listings
  { asset-id: uint }
  {
    seller: principal,
    tokens-for-sale: uint,
    price-per-token: uint,
    active: bool
  }
)

(define-map oracles
  { oracle: principal }
  { authorized: bool }
)

(define-map auctions
  { auction-id: uint }
  {
    asset-id: uint,
    seller: principal,
    tokens-amount: uint,
    start-price: uint,
    end-price: uint,
    start-block: uint,
    duration: uint,
    price-drop-interval: uint,
    active: bool
  }
)

(define-public (authorize-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set oracles { oracle: oracle } { authorized: true })
    (ok true)
  )
)

(define-public (revoke-oracle (oracle principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set oracles { oracle: oracle } { authorized: false })
    (ok true)
  )
)

(define-public (register-asset 
  (name (string-ascii 50))
  (description (string-ascii 200))
  (category (string-ascii 20))
  (total-tokens uint)
  (token-price uint)
  (expires-at (optional uint))
  (renewable bool)
)
  (let
    (
      (asset-id (var-get next-asset-id))
      (current-block u1)
    )
    (asserts! (> total-tokens u0) ERR_INVALID_AMOUNT)
    (asserts! (> token-price u0) ERR_INVALID_PRICE)
    (asserts! (match expires-at
      some-expiry (> some-expiry (+ burn-block-height u1))
      true
    ) ERR_INVALID_EXPIRY)
    
    (map-set assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        category: category,
        total-tokens: total-tokens,
        token-price: token-price,
        verified: false,
        oracle: none,
        created-at: current-block,
        expires-at: expires-at,
        renewable: renewable
      }
    )
    
    (map-set asset-tokens
      { asset-id: asset-id, holder: tx-sender }
      { amount: total-tokens }
    )
    
    (var-set next-asset-id (+ asset-id u1))
    (ok asset-id)
  )
)

(define-public (verify-asset (asset-id uint) (oracle principal))
  (let
    (
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR_ASSET_NOT_FOUND))
      (oracle-auth (default-to { authorized: false } (map-get? oracles { oracle: oracle })))
    )
    (asserts! (get authorized oracle-auth) ERR_UNAUTHORIZED)
    
    (map-set assets
      { asset-id: asset-id }
      (merge asset { verified: true, oracle: (some oracle) })
    )
    (ok true)
  )
)

(define-public (transfer-tokens (asset-id uint) (to principal) (amount uint))
  (let
    (
      (sender-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender })))
      (receiver-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: asset-id, holder: to })))
    )
    (asserts! (>= (get amount sender-balance) amount) ERR_INSUFFICIENT_TOKENS)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (map-set asset-tokens
      { asset-id: asset-id, holder: tx-sender }
      { amount: (- (get amount sender-balance) amount) }
    )
    
    (map-set asset-tokens
      { asset-id: asset-id, holder: to }
      { amount: (+ (get amount receiver-balance) amount) }
    )
    
    (ok true)
  )
)

(define-public (list-tokens-for-sale (asset-id uint) (tokens-amount uint) (price-per-token uint))
  (let
    (
      (holder-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender })))
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR_ASSET_NOT_FOUND))
    )
    (asserts! (get verified asset) ERR_ASSET_NOT_VERIFIED)
    (asserts! (match (get expires-at asset)
      some-expiry (> some-expiry burn-block-height)
      true
    ) ERR_ASSET_EXPIRED)
    (asserts! (>= (get amount holder-balance) tokens-amount) ERR_INSUFFICIENT_TOKENS)
    (asserts! (> tokens-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> price-per-token u0) ERR_INVALID_PRICE)
    
    (map-set asset-listings
      { asset-id: asset-id }
      {
        seller: tx-sender,
        tokens-for-sale: tokens-amount,
        price-per-token: price-per-token,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (buy-tokens (asset-id uint) (tokens-amount uint))
  (let
    (
      (listing (unwrap! (map-get? asset-listings { asset-id: asset-id }) ERR_ASSET_NOT_FOUND))
      (total-cost (* (get price-per-token listing) tokens-amount))
      (fee-amount (/ (* total-cost (var-get platform-fee)) u10000))
      (seller-amount (- total-cost fee-amount))
      (buyer-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender })))
      (seller-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: asset-id, holder: (get seller listing) })))
    )
    (asserts! (get active listing) ERR_ASSET_NOT_FOUND)
    (asserts! (<= tokens-amount (get tokens-for-sale listing)) ERR_INSUFFICIENT_TOKENS)
    (asserts! (> tokens-amount u0) ERR_INVALID_AMOUNT)
    
    (try! (stx-transfer? total-cost tx-sender (get seller listing)))
    
    (if (> fee-amount u0)
      (try! (stx-transfer? fee-amount (get seller listing) CONTRACT_OWNER))
      true
    )
    
    (map-set asset-tokens
      { asset-id: asset-id, holder: tx-sender }
      { amount: (+ (get amount buyer-balance) tokens-amount) }
    )
    
    (map-set asset-tokens
      { asset-id: asset-id, holder: (get seller listing) }
      { amount: (- (get amount seller-balance) tokens-amount) }
    )
    
    (if (is-eq tokens-amount (get tokens-for-sale listing))
      (map-set asset-listings
        { asset-id: asset-id }
        (merge listing { active: false })
      )
      (map-set asset-listings
        { asset-id: asset-id }
        (merge listing { tokens-for-sale: (- (get tokens-for-sale listing) tokens-amount) })
      )
    )
    
    (ok true)
  )
)

(define-public (cancel-listing (asset-id uint))
  (let
    (
      (listing (unwrap! (map-get? asset-listings { asset-id: asset-id }) ERR_ASSET_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get seller listing)) ERR_UNAUTHORIZED)
    
    (map-set asset-listings
      { asset-id: asset-id }
      (merge listing { active: false })
    )
    (ok true)
  )
)

(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT)
    (var-set platform-fee new-fee)
    (ok true)
  )
)

(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-asset-tokens (asset-id uint) (holder principal))
  (default-to { amount: u0 } (map-get? asset-tokens { asset-id: asset-id, holder: holder }))
)

(define-read-only (get-asset-listing (asset-id uint))
  (map-get? asset-listings { asset-id: asset-id })
)

(define-read-only (get-platform-fee)
  (var-get platform-fee)
)

(define-read-only (get-next-asset-id)
  (var-get next-asset-id)
)

(define-read-only (is-oracle-authorized (oracle principal))
  (default-to { authorized: false } (map-get? oracles { oracle: oracle }))
)

(define-read-only (get-total-asset-value (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (ok (* (get total-tokens asset) (get token-price asset)))
    ERR_ASSET_NOT_FOUND
  )
)

(define-public (renew-asset (asset-id uint) (new-expiry uint))
  (let
    (
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR_ASSET_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get owner asset)) ERR_UNAUTHORIZED)
    (asserts! (get renewable asset) ERR_UNAUTHORIZED)
    (asserts! (> new-expiry burn-block-height) ERR_INVALID_EXPIRY)
    
    (map-set assets
      { asset-id: asset-id }
      (merge asset { expires-at: (some new-expiry) })
    )
    (ok true)
  )
)

(define-read-only (is-asset-expired (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (match (get expires-at asset)
      some-expiry (>= burn-block-height some-expiry)
      false
    )
    true
  )
)

(define-read-only (get-asset-expiry (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (get expires-at asset)
    none
  )
)

(define-read-only (is-asset-renewable (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (get renewable asset)
    false
  )
)

(define-public (create-dutch-auction 
  (asset-id uint)
  (tokens-amount uint)
  (start-price uint)
  (end-price uint)
  (duration uint)
  (price-drop-interval uint)
)
  (let
    (
      (auction-id (var-get next-auction-id))
      (holder-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: asset-id, holder: tx-sender })))
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) ERR_ASSET_NOT_FOUND))
    )
    (asserts! (get verified asset) ERR_ASSET_NOT_VERIFIED)
    (asserts! (match (get expires-at asset)
      some-expiry (> some-expiry burn-block-height)
      true
    ) ERR_ASSET_EXPIRED)
    (asserts! (>= (get amount holder-balance) tokens-amount) ERR_INSUFFICIENT_TOKENS)
    (asserts! (> tokens-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> start-price u0) ERR_INVALID_PRICE)
    (asserts! (> end-price u0) ERR_INVALID_PRICE)
    (asserts! (< end-price start-price) ERR_INVALID_PRICE)
    (asserts! (> duration u10) ERR_INVALID_DURATION)
    (asserts! (> price-drop-interval u0) ERR_INVALID_PRICE_DROP)
    (asserts! (<= price-drop-interval duration) ERR_INVALID_PRICE_DROP)
    
    (map-set auctions
      { auction-id: auction-id }
      {
        asset-id: asset-id,
        seller: tx-sender,
        tokens-amount: tokens-amount,
        start-price: start-price,
        end-price: end-price,
        start-block: burn-block-height,
        duration: duration,
        price-drop-interval: price-drop-interval,
        active: true
      }
    )
    
    (var-set next-auction-id (+ auction-id u1))
    (ok auction-id)
  )
)

(define-public (bid-on-auction (auction-id uint))
  (let
    (
      (auction (unwrap! (map-get? auctions { auction-id: auction-id }) ERR_AUCTION_NOT_FOUND))
      (current-price (unwrap! (get-current-auction-price auction-id) ERR_AUCTION_ENDED))
      (total-cost (* current-price (get tokens-amount auction)))
      (fee-amount (/ (* total-cost (var-get platform-fee)) u10000))
      (seller-amount (- total-cost fee-amount))
      (buyer-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: (get asset-id auction), holder: tx-sender })))
      (seller-balance (default-to { amount: u0 } 
        (map-get? asset-tokens { asset-id: (get asset-id auction), holder: (get seller auction) })))
    )
    (asserts! (get active auction) ERR_AUCTION_ENDED)
    (asserts! (not (is-eq tx-sender (get seller auction))) ERR_UNAUTHORIZED)
    
    (try! (stx-transfer? total-cost tx-sender (get seller auction)))
    
    (if (> fee-amount u0)
      (try! (stx-transfer? fee-amount (get seller auction) CONTRACT_OWNER))
      true
    )
    
    (map-set asset-tokens
      { asset-id: (get asset-id auction), holder: tx-sender }
      { amount: (+ (get amount buyer-balance) (get tokens-amount auction)) }
    )
    
    (map-set asset-tokens
      { asset-id: (get asset-id auction), holder: (get seller auction) }
      { amount: (- (get amount seller-balance) (get tokens-amount auction)) }
    )
    
    (map-set auctions
      { auction-id: auction-id }
      (merge auction { active: false })
    )
    
    (ok current-price)
  )
)

(define-public (cancel-auction (auction-id uint))
  (let
    (
      (auction (unwrap! (map-get? auctions { auction-id: auction-id }) ERR_AUCTION_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get seller auction)) ERR_UNAUTHORIZED)
    (asserts! (get active auction) ERR_AUCTION_ENDED)
    
    (map-set auctions
      { auction-id: auction-id }
      (merge auction { active: false })
    )
    (ok true)
  )
)

(define-read-only (get-auction (auction-id uint))
  (map-get? auctions { auction-id: auction-id })
)

(define-read-only (get-current-auction-price (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction
      (let
        (
          (blocks-elapsed (- burn-block-height (get start-block auction)))
          (auction-ended (>= blocks-elapsed (get duration auction)))
          (price-steps (/ blocks-elapsed (get price-drop-interval auction)))
          (total-price-steps (/ (get duration auction) (get price-drop-interval auction)))
          (price-drop-per-step (/ (- (get start-price auction) (get end-price auction)) total-price-steps))
          (current-price (- (get start-price auction) (* price-steps price-drop-per-step)))
        )
        (if (get active auction)
          (if auction-ended
            (err ERR_AUCTION_ENDED)
            (ok (if (>= current-price (get end-price auction)) current-price (get end-price auction)))
          )
          (err ERR_AUCTION_ENDED)
        )
      )
    (err ERR_AUCTION_NOT_FOUND)
  )
)

(define-read-only (get-next-auction-id)
  (var-get next-auction-id)
)

(define-read-only (is-auction-active (auction-id uint))
  (match (map-get? auctions { auction-id: auction-id })
    auction
      (let
        (
          (blocks-elapsed (- burn-block-height (get start-block auction)))
          (auction-ended (>= blocks-elapsed (get duration auction)))
        )
        (and (get active auction) (not auction-ended))
      )
    false
  )
)
