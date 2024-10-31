
;; tokenized_real_estate

(define-map properties uint (tuple (value uint) (owner principal) (total-tokens uint) (rental-income uint)))
(define-map token-holders (tuple (property-id uint) (holder principal)) uint)
(define-map maintenance-requests uint (tuple (description (string-ascii 256)) (votes uint) (approved bool)))
(define-map property-maintenance uint (tuple (request-id uint) (description (string-ascii 256)) (status (string-ascii 20))))


