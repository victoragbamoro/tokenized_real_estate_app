
;; tokenized_real_estate

(define-map properties uint (tuple (value uint) (owner principal) (total-tokens uint) (rental-income uint)))
(define-map token-holders (tuple (property-id uint) (holder principal)) uint)
(define-map maintenance-requests uint (tuple (description (string-ascii 256)) (votes uint) (approved bool)))
(define-map property-maintenance uint (tuple (request-id uint) (description (string-ascii 256)) (status (string-ascii 20))))

(define-map property-listings uint (tuple (listed bool) (price uint)))

(define-public (initialize (property-id uint) (property-value uint) (owner principal))
  (begin
    ;; Initialize property details
    (map-set properties property-id (tuple (value property-value) (owner owner) (total-tokens u0) (rental-income u0)))
    (ok (tuple (property-id property-id) (property-value property-value) (owner owner)))))

(define-public (issue-tokens (property-id uint) (amount uint))
  (let ((property (map-get? properties property-id)))
    (if (is-none property)
      (err "Property does not exist.")
      (let ((current-property (unwrap! property (err "Property does not exist."))))
        (let ((total-tokens (get total-tokens current-property)))
          (begin
            ;; Update total tokens and add holder
            (map-set properties property-id (tuple (value (get value current-property))
                                                   (owner (get owner current-property))
                                                   (total-tokens (+ total-tokens amount))
                                                   (rental-income (get rental-income current-property))))
            (map-set token-holders (tuple (property-id property-id) (holder tx-sender))
                     (+ (default-to u0 (map-get? token-holders (tuple (property-id property-id) (holder tx-sender)))) amount))
            (ok "Tokens issued successfully.")))))))

(define-public (transfer-tokens (property-id uint) (to principal) (amount uint))
  (let ((current-balance (map-get? token-holders (tuple (property-id property-id) (holder tx-sender)))))
    (if (is-none current-balance)
      (err "You do not hold tokens for this property.")
      (let ((balance (unwrap! current-balance (err "You do not hold tokens for this property."))))
        (if (< balance amount)
          (err "Insufficient tokens.")
          (begin
            ;; Update balances
            (map-set token-holders (tuple (property-id property-id) (holder tx-sender)) (- balance amount))
            (let ((recipient-balance (map-get? token-holders (tuple (property-id property-id) (holder to)))))
              (map-set token-holders (tuple (property-id property-id) (holder to))
                       (+ (default-to u0 recipient-balance) amount))
              (ok "Tokens transferred successfully."))))))))

(define-public (distribute-rental-income (property-id uint) (amount uint))
  (let ((property (map-get? properties property-id)))
    (if (is-none property)
      (err "Property does not exist.")
      (let ((current-property (unwrap! property (err "Property does not exist."))))
        (let ((rental-income (get rental-income current-property)))
          (begin
            ;; Update rental income
            (map-set properties property-id (tuple (value (get value current-property))
                                                   (owner (get owner current-property))
                                                   (total-tokens (get total-tokens current-property))
                                                   (rental-income (+ rental-income amount))))
            (ok "Rental income distributed.")))))))


(define-public (claim-rental-income (property-id uint))
  (let ((property (map-get? properties property-id)))
    (if (is-none property)
      (err "Property does not exist.")
      (let ((current-property (unwrap! property (err "Property does not exist."))))
        (let ((rental-income (get rental-income current-property))
              (holder-share (map-get? token-holders (tuple (property-id property-id) (holder tx-sender)))))
          (if (is-none holder-share)
            (err "You do not hold tokens for this property.")
            (let ((share (unwrap! holder-share (err "Error fetching your token share."))))
              (let ((amount-to-claim (/ (* rental-income share) (get total-tokens current-property))))
                ;; Logic for transferring claimed rental income to the holder
                ;; Here you would implement the transfer of the claimed amount to the user
                (begin
                  ;; Placeholder for actual transfer logic
                  (ok (tuple (claimed amount-to-claim))))))))))))


(define-public (list-property (property-id uint) (price uint))
  (let ((property (map-get? properties property-id)))
    (if (is-none property)
      (err "Property does not exist.")
      (let ((current-property (unwrap! property (err "Property does not exist."))))
        (if (not (is-eq tx-sender (get owner current-property)))
          (err "Only the owner can list the property.")
          (begin
            (map-set property-listings property-id (tuple (listed true) (price price)))
            (ok "Property listed successfully.")))))))

;; delist property function
(define-public (delist-property (property-id uint))
  (let ((listing (map-get? property-listings property-id)))
    (if (is-none listing)
      (err "Property is not listed.")
      (let ((current-listing (unwrap! listing (err "Property is not listed."))))
        (if (not (get listed current-listing))
          (err "Property is already not listed.")
          (begin
            (map-set property-listings property-id (tuple (listed false) (price u0)))
            (ok "Property delisted successfully.")))))))


;; function to vote on a maintenance request
(define-public (vote-maintenance-request (request-id uint))
  (let ((request (map-get? maintenance-requests request-id)))
    (if (is-none request)
      (err "Maintenance request does not exist.")
      (let ((current-request (unwrap! request (err "Maintenance request does not exist."))))
        (begin
          (map-set maintenance-requests request-id 
                    (tuple (description (get description current-request))
                           (votes (+ u1 (get votes current-request)))
                           (approved (get approved current-request))))
          (ok "Vote recorded successfully."))))))
