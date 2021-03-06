{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE LiberalTypeSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Main (properties)
-- Copyright   :  (C) 2012-14 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable
--
-- This module provides a set of QuickCheck properties that can be run through
-- test-framework to validate a number of expected behaviors of the library.
-----------------------------------------------------------------------------
module Main where

import Control.Applicative
import Control.Lens
import Test.QuickCheck
import Test.QuickCheck.Function
import Test.Framework.TH
import Test.Framework.Providers.QuickCheck2
import Data.Char (isAlphaNum, isAscii, toUpper)
import Data.Text.Strict.Lens
import Data.Maybe
import Data.List.Lens
import Data.Functor.Compose
import Numeric (showHex, showOct, showSigned)
import Numeric.Lens
import Control.Lens.Properties (isIso, isLens, isPrism, isSetter, isTraversal)

-- an illegal lens
bad :: Lens' (Int,Int) Int
bad f (a,b) = (,) b <$> f a

badIso :: Iso' Int Bool
badIso = iso even fromEnum

-- Control.Lens.Type
prop_1                               = isLens (_1 :: Lens' (Int,Double,()) Int)
prop_2                               = isLens (_2 :: Lens' (Int,Bool) Bool)
prop_3                               = isLens (_3 :: Lens' (Int,Bool,()) ())
prop_4                               = isLens (_4 :: Lens' (Int,Bool,(),Maybe Int) (Maybe Int))
prop_5                               = isLens (_5 :: Lens' ((),(),(),(),Int) Int)

prop_2_2                             = isLens (_2._2 :: Lens' (Int,(Int,Bool),Double) Bool)

-- prop_illegal_lens                    = expectFailure $ isLens bad
-- prop_illegal_traversal               = expectFailure $ isTraversal bad
-- prop_illegal_setter                  = expectFailure $ isSetter bad
-- prop_illegal_iso                     = expectFailure $ isIso badIso

-- Control.Lens.Setter
prop_mapped                          = isSetter (mapped :: Setter' [Int] Int)
prop_mapped_mapped                   = isSetter (mapped.mapped :: Setter' [Maybe Int] Int)

prop_both                            = isTraversal (both           :: Traversal' (Int,Int) Int)
prop_traverseLeft                    = isTraversal (_Left          :: Traversal' (Either Int Bool) Int)
prop_traverseRight                   = isTraversal (_Right         :: Traversal' (Either Int Bool) Bool)

prop_simple                          = isIso (simple :: Iso' Int Int)
--prop_enum                            = isIso (enum :: Iso' Int Char)

prop__Left                           = isPrism (_Left :: Prism' (Either Int Bool) Int)
prop__Right                          = isPrism (_Right :: Prism' (Either Int Bool) Bool)
prop__Just                           = isPrism (_Just :: Prism' (Maybe Int) Int)

-- Data.List.Lens
prop_prefixed s                      = isPrism (prefixed s :: Prism' String String)

-- Data.Text.Lens
prop_text s                          = s^.packed.from packed == s
--prop_text                           = isIso packed

-- Numeric.Lens
prop_base_show (n :: Integer) =
  conjoin [ show n == n ^. re (base 10)
          , showSigned showOct 0 n "" == n ^. re (base 8)
          , showSigned showHex 0 n "" == n ^. re (base 16)
          ]
prop_base_read (n :: Integer) =
  conjoin [ show n ^? base 10 == Just n
          , showSigned showOct 0 n "" ^? base 8  == Just n
          , showSigned showHex 0 n "" ^? base 16 == Just n
          , map toUpper (showSigned showHex 0 n "") ^? base 16 == Just n
          ]
prop_base_readFail (s :: String) =
  forAll (choose (2,36)) $ \b ->
    not isValid ==> s ^? base b == Nothing
  where
    isValid = (not . null) sPos && all isValidChar sPos
    sPos = case s of { ('-':s') -> s'; _ -> s }
    isValidChar c = isAscii c && isAlphaNum c

main :: IO ()
main = $defaultMainGenerator
