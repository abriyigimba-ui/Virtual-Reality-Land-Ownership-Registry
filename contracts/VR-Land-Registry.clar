
(define-non-fungible-token vr-land uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-not-owner (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-coordinates (err u104))
(define-constant err-transfer-restricted (err u105))
(define-constant err-not-community-member (err u106))
(define-constant err-insufficient-reputation (err u107))
(define-constant err-parcel-locked (err u108))
(define-constant err-invalid-price (err u109))
(define-constant err-community-not-found (err u110))
(define-constant err-parcel-rented (err u111))
(define-constant err-rental-not-found (err u112))
(define-constant err-rental-expired (err u113))
(define-constant err-not-renter (err u114))

(define-data-var next-parcel-id uint u1)
(define-data-var total-parcels uint u0)

(define-map parcel-data
  uint
  {
    x-coord: int,
    y-coord: int,
    z-coord: int,
    world-id: (string-ascii 32),
    size: uint,
    created-at: uint,
    community-id: uint,
    is-locked: bool,
    min-reputation: uint
  }
)

(define-map community-rules
  uint
  {
    name: (string-ascii 64),
    min-reputation: uint,
    transfer-cooldown: uint,
    max-transfers-per-day: uint,
    requires-approval: bool,
    creator: principal
  }
)

(define-map member-reputation
  { community-id: uint, member: principal }
  { reputation: uint, last-activity: uint }
)

(define-map transfer-history
  { parcel-id: uint, day: uint }
  uint
)

(define-map parcel-approvals
  { parcel-id: uint, approved-by: principal }
  bool
)

(define-map marketplace-listings
  uint
  {
    price: uint,
    seller: principal,
    listed-at: uint,
    expires-at: uint
  }
)

(define-map world-metadata
  (string-ascii 32)
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    creator: principal,
    created-at: uint
  }
)

(define-public (register-world (world-id (string-ascii 32)) (name (string-ascii 64)) (description (string-ascii 256)))
  (let
    (
      (existing (map-get? world-metadata world-id))
    )
    (asserts! (is-none existing) err-already-exists)
    (asserts! (> (len name) u0) err-invalid-coordinates)
    (map-set world-metadata world-id
      {
        name: name,
        description: description,
        creator: tx-sender,
        created-at: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-public (update-world-metadata (world-id (string-ascii 32)) (name (string-ascii 64)) (description (string-ascii 256)))
  (let
    (
      (world (unwrap! (map-get? world-metadata world-id) err-community-not-found))
    )
    (asserts! (is-eq tx-sender (get creator world)) err-owner-only)
    (map-set world-metadata world-id
      {
        name: name,
        description: description,
        creator: (get creator world),
        created-at: (get created-at world)
      }
    )
    (ok true)
  )
)

(define-map parcel-rentals
  uint
  {
    renter: principal,
    rental-price: uint,
    start-block: uint,
    end-block: uint,
    owner: principal
  }
)

(define-map rental-offers
  uint
  {
    price-per-block: uint,
    max-duration: uint,
    owner: principal,
    active: bool
  }
)

(define-public (mint-parcel (x-coord int) (y-coord int) (z-coord int) (world-id (string-ascii 32)) (size uint) (community-id uint))
  (let
    (
      (parcel-id (var-get next-parcel-id))
      (community (map-get? community-rules community-id))
    )
    (asserts! (is-some community) err-community-not-found)
    (asserts! (> size u0) err-invalid-coordinates)
    (asserts! (is-none (get-parcel-by-coordinates x-coord y-coord z-coord world-id)) err-already-exists)
    (try! (nft-mint? vr-land parcel-id tx-sender))
    (map-set parcel-data parcel-id
      {
        x-coord: x-coord,
        y-coord: y-coord,
        z-coord: z-coord,
        world-id: world-id,
        size: size,
        created-at: stacks-block-height,
        community-id: community-id,
        is-locked: false,
        min-reputation: (get min-reputation (unwrap-panic community))
      }
    )
    (var-set next-parcel-id (+ parcel-id u1))
    (var-set total-parcels (+ (var-get total-parcels) u1))
    (ok parcel-id)
  )
)

(define-public (transfer-parcel (parcel-id uint) (recipient principal))
  (let
    (
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
      (community (unwrap! (map-get? community-rules (get community-id parcel)) err-community-not-found))
      (current-day (/ stacks-block-height u144))
      (transfers-today (default-to u0 (map-get? transfer-history { parcel-id: parcel-id, day: current-day })))
      (recipient-reputation (get-member-reputation (get community-id parcel) recipient))
    )
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? vr-land parcel-id) err-not-found)) err-not-owner)
    (asserts! (not (get is-locked parcel)) err-parcel-locked)
    (asserts! (>= recipient-reputation (get min-reputation community)) err-insufficient-reputation)
    (asserts! (< transfers-today (get max-transfers-per-day community)) err-transfer-restricted)
    (if (get requires-approval community)
      (asserts! (default-to false (map-get? parcel-approvals { parcel-id: parcel-id, approved-by: (get creator community) })) err-transfer-restricted)
      true
    )
    (try! (nft-transfer? vr-land parcel-id tx-sender recipient))
    (map-set transfer-history { parcel-id: parcel-id, day: current-day } (+ transfers-today u1))
    (update-member-reputation (get community-id parcel) recipient u1)
    (ok true)
  )
)

(define-public (create-community (name (string-ascii 64)) (min-reputation uint) (transfer-cooldown uint) (max-transfers-per-day uint) (requires-approval bool))
  (let
    (
      (community-id (+ (var-get next-parcel-id) u1000))
    )
    (map-set community-rules community-id
      {
        name: name,
        min-reputation: min-reputation,
        transfer-cooldown: transfer-cooldown,
        max-transfers-per-day: max-transfers-per-day,
        requires-approval: requires-approval,
        creator: tx-sender
      }
    )
    (update-member-reputation community-id tx-sender u100)
    (ok community-id)
  )
)

(define-public (list-parcel (parcel-id uint) (price uint) (duration uint))
  (let
    (
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? vr-land parcel-id) err-not-found)) err-not-owner)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (not (get is-locked parcel)) err-parcel-locked)
    (map-set marketplace-listings parcel-id
      {
        price: price,
        seller: tx-sender,
        listed-at: stacks-block-height,
        expires-at: (+ stacks-block-height duration)
      }
    )
    (ok true)
  )
)

(define-public (buy-parcel (parcel-id uint))
  (let
    (
      (listing (unwrap! (map-get? marketplace-listings parcel-id) err-not-found))
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
    )
    (asserts! (< stacks-block-height (get expires-at listing)) err-not-found)
    (asserts! (>= (stx-get-balance tx-sender) (get price listing)) err-invalid-price)
    (try! (stx-transfer? (get price listing) tx-sender (get seller listing)))
    (try! (nft-transfer? vr-land parcel-id (get seller listing) tx-sender))
    (map-delete marketplace-listings parcel-id)
    (update-member-reputation (get community-id parcel) tx-sender u5)
    (ok true)
  )
)

(define-public (approve-transfer (parcel-id uint) (approved bool))
  (let
    (
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
      (community (unwrap! (map-get? community-rules (get community-id parcel)) err-community-not-found))
    )
    (asserts! (is-eq tx-sender (get creator community)) err-owner-only)
    (map-set parcel-approvals { parcel-id: parcel-id, approved-by: tx-sender } approved)
    (ok true)
  )
)

(define-public (lock-parcel (parcel-id uint))
  (let
    (
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? vr-land parcel-id) err-not-found)) err-not-owner)
    (map-set parcel-data parcel-id (merge parcel { is-locked: true }))
    (ok true)
  )
)

(define-public (unlock-parcel (parcel-id uint))
  (let
    (
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? vr-land parcel-id) err-not-found)) err-not-owner)
    (map-set parcel-data parcel-id (merge parcel { is-locked: false }))
    (ok true)
  )
)

(define-public (offer-rental (parcel-id uint) (price-per-block uint) (max-duration uint))
  (let
    (
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? vr-land parcel-id) err-not-found)) err-not-owner)
    (asserts! (not (get is-locked parcel)) err-parcel-locked)
    (asserts! (is-none (map-get? parcel-rentals parcel-id)) err-parcel-rented)
    (asserts! (> price-per-block u0) err-invalid-price)
    (asserts! (> max-duration u0) err-invalid-coordinates)
    (map-set rental-offers parcel-id
      {
        price-per-block: price-per-block,
        max-duration: max-duration,
        owner: tx-sender,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (rent-parcel (parcel-id uint) (duration uint))
  (let
    (
      (offer (unwrap! (map-get? rental-offers parcel-id) err-rental-not-found))
      (parcel (unwrap! (map-get? parcel-data parcel-id) err-not-found))
      (total-cost (* (get price-per-block offer) duration))
      (owner (get owner offer))
    )
    (asserts! (get active offer) err-rental-not-found)
    (asserts! (<= duration (get max-duration offer)) err-invalid-coordinates)
    (asserts! (is-none (map-get? parcel-rentals parcel-id)) err-parcel-rented)
    (asserts! (>= (stx-get-balance tx-sender) total-cost) err-invalid-price)
    (try! (stx-transfer? total-cost tx-sender owner))
    (map-set parcel-rentals parcel-id
      {
        renter: tx-sender,
        rental-price: total-cost,
        start-block: stacks-block-height,
        end-block: (+ stacks-block-height duration),
        owner: owner
      }
    )
    (map-set rental-offers parcel-id (merge offer { active: false }))
    (ok true)
  )
)

(define-public (end-rental (parcel-id uint))
  (let
    (
      (rental (unwrap! (map-get? parcel-rentals parcel-id) err-rental-not-found))
    )
    (asserts! (or (is-eq tx-sender (get renter rental)) (is-eq tx-sender (get owner rental))) err-not-renter)
    (asserts! (>= stacks-block-height (get end-block rental)) err-rental-expired)
    (map-delete parcel-rentals parcel-id)
    (ok true)
  )
)

(define-public (cancel-rental-offer (parcel-id uint))
  (let
    (
      (offer (unwrap! (map-get? rental-offers parcel-id) err-rental-not-found))
    )
    (asserts! (is-eq tx-sender (get owner offer)) err-not-owner)
    (asserts! (is-none (map-get? parcel-rentals parcel-id)) err-parcel-rented)
    (map-set rental-offers parcel-id (merge offer { active: false }))
    (ok true)
  )
)

(define-private (update-member-reputation (community-id uint) (member principal) (points uint))
  (let
    (
      (current-rep (default-to { reputation: u0, last-activity: u0 } (map-get? member-reputation { community-id: community-id, member: member })))
    )
    (map-set member-reputation { community-id: community-id, member: member }
      {
        reputation: (+ (get reputation current-rep) points),
        last-activity: stacks-block-height
      }
    )
  )
)

(define-read-only (get-last-token-id)
  (ok (- (var-get next-parcel-id) u1))
)

(define-read-only (get-token-uri (parcel-id uint))
  (ok none)
)

(define-read-only (get-owner (parcel-id uint))
  (ok (nft-get-owner? vr-land parcel-id))
)

(define-read-only (get-parcel-info (parcel-id uint))
  (map-get? parcel-data parcel-id)
)

(define-read-only (get-community-info (community-id uint))
  (map-get? community-rules community-id)
)

(define-read-only (get-member-reputation (community-id uint) (member principal))
  (get reputation (default-to { reputation: u0, last-activity: u0 } (map-get? member-reputation { community-id: community-id, member: member })))
)

(define-read-only (get-parcel-by-coordinates (x int) (y int) (z int) (world-id (string-ascii 32)))
  (let
    (
      (parcel-id u1)
    )
    (fold check-parcel-coordinates (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10) none)
  )
)

(define-read-only (get-marketplace-listing (parcel-id uint))
  (map-get? marketplace-listings parcel-id)
)

(define-read-only (get-total-parcels)
  (var-get total-parcels)
)

(define-read-only (get-rental-info (parcel-id uint))
  (map-get? parcel-rentals parcel-id)
)

(define-read-only (get-rental-offer (parcel-id uint))
  (map-get? rental-offers parcel-id)
)

(define-read-only (is-rental-active (parcel-id uint))
  (match (map-get? parcel-rentals parcel-id)
    rental (< stacks-block-height (get end-block rental))
    false
  )
)

(define-read-only (can-use-parcel (parcel-id uint) (user principal))
  (or
    (is-eq user (unwrap! (nft-get-owner? vr-land parcel-id) false))
    (match (map-get? parcel-rentals parcel-id)
      rental (and (is-eq user (get renter rental)) (< stacks-block-height (get end-block rental)))
      false
    )
  )
)

(define-private (check-parcel-coordinates (parcel-id uint) (found (optional uint)))
  (if (is-some found)
    found
    (match (map-get? parcel-data parcel-id)
      parcel-info none
      none
    )
  )
)
