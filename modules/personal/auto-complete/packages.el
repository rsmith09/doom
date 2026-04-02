;;; packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

(package! company :pin "42d3897308a992cd2268ba2d4e2ec013fc6c961e")
(package! company-box :pin "c4f2e243fba03c11e46b1600b124e036f2be7691")

(package! corfu :pin "abfe0003d71b61ffdcf23fc6e546643486daeb69")
(package! cape :pin "2b2a5c5bef16eddcce507d9b5804e5a0cc9481ae")
(when (modulep! +icons)
  (package! nerd-icons-corfu :pin "f821e953b1a3dc9b381bc53486aabf366bf11cb1"))
(when (modulep! :editor snippets)
  (package! yasnippet-capf :pin "f53c42a996b86fc95b96bdc2deeb58581f48c666"))
(when (and (not (modulep! :completion vertico))
           (modulep! +orderless))
  ;; Enabling +orderless without vertico should be fairly niche enough that to
  ;; save contributor headaches we should only pin vertico's orderless and leave
  ;; this one unpinned.
  (package! orderless))
