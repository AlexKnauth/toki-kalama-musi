#lang racket/base

(provide wordtokens->musicxml)

(require racket/list
         racket/match
         music/data/time/main
         music/data/chord/main
         "../toki-pona.rkt"
         "../common/musicxml.rkt"
         "chord-names.rkt")
(module+ main
  (require racket/file
           txexpr
           music/notation/musicxml/musicxml-file
           music/notation/musicxml/read/musicxml-file
           "../common/command-line.rkt"))
(module+ test
  (require racket/file
           racket/runtime-path
           txexpr
           music/notation/musicxml/read/musicxml-file)
  (define-runtime-path introduction.toki-pona.txt
    "../../../examples/introduction.toki-pona.txt")
  (define-runtime-path introduction.chromatic-chords-in-C.musicxml
    "../../../examples/introduction.chromatic-chords-in-C.musicxml"))

(module+ test
  (define introduction-wordtokens
    (toki-pona-string->wordtokens
     (file->string introduction.toki-pona.txt)))
  (check-txexprs-equal?
   (wordtokens->musicxml introduction-wordtokens)
   (read-musicxml-file introduction.chromatic-chords-in-C.musicxml)))

;; ---------------------------------------------------------

(define chord-kind-name/kind-table
  (list (list "sus4" sus-4)
        (list "sus2" sus-2)
        (list "5" open-power)
        (list "" major-triad)
        (list "6" major-add-6)
        (list "m6" minor-add-6)
        (list "7" dominant-7)
        (list "m" minor-triad)
        (list "Maj7" major-7)
        (list "m7" minor-7)))

;; wordtokens->score-partwise : WordTokens -> MXexpr
(define (wordtokens->musicxml wts)
  (lasting-chords->musicxml (wordtokens->lasting-chords wts)))

;; wordtokens->lasting-chords : WordTokens -> [Listof [Lasting Chord]]
(define (wordtokens->lasting-chords wts)
  (wordtokens-map-words->lasting-chords word->lasting-chords wts))

;; word->lasting-chords : Word -> [Listof [Lasting Chord]]
(define (word->lasting-chords w)
  (map syllable->lasting-chord w))

;; syllable->lasting-chord : Syllable -> [Lasting Chord]
(define/match (syllable->lasting-chord s)
  [[(syllable up? start end)]
   ;; TODO: accent if up? is true
   (lasting duration-eighth
            (chord (chord-root-name->note
                    (syllable-start->chord-name-root start))
                   (chord-kind-name->kind
                    (syllable-end->chord-name-kind end))))])

(define (chord-kind-name->kind s)
  (second (or (assoc s chord-kind-name/kind-table)
              (error 'chord-kind-name->kind "unknown chord kind name: ~v" s))))

;; ---------------------------------------------------------

(module+ main
  (command-line/file-suffix-bidirectional
   #:program "chromatic-chord-names"
   #:input-suffix ".toki-pona.txt"
   #:output-suffix ".chromatic-chords-in-C.musicxml"
   #:force (λ (ip op)
             (write-musicxml-file op
                                  (wordtokens->musicxml
                                   (toki-pona-string->wordtokens (file->string ip)))
                                  #:exists 'replace))
   #:check (λ (ip op)
             (check-txexprs-equal? (wordtokens->musicxml
                                    (toki-pona-string->wordtokens (file->string ip)))
                                   (read-musicxml-file op)))
   #:infer (λ (ip op)
             (write-musicxml-file op
                                  (wordtokens->musicxml
                                   (toki-pona-string->wordtokens (file->string ip)))
                                  #:exists 'error))))
