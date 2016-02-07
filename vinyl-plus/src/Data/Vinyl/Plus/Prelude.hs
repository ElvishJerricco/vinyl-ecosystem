module Data.Vinyl.Plus.Prelude where

import           Prelude                 hiding (foldl, head, tail, unzip, zip,
                                          zip3, zip4)

import           Data.Functor.Constant
import           Data.Functor.Identity
import           Data.Functor.Product
import           Data.Monoid             (Endo (..))
import           Data.Vinyl.Core
import           Data.Vinyl.Functor      (Lift (..))
import           Data.Vinyl.Plus.CoRec
import           Data.Vinyl.Plus.Functor
import           Data.Vinyl.Plus.Types
import           Data.Vinyl.TypeLevel

-- This needs to be imported qualified

head :: Rec f (r ': rs) -> f r
head (r :& _) = r

tail :: Rec f (r ': rs) -> Rec f rs
tail (_ :& rs) = rs

cons :: f r -> Rec f rs -> Rec f (r ': rs)
cons = (:&)

uncons :: Rec f (r ': rs) -> (f r, Rec f rs)
uncons (r :& rs) = (r, rs)

append :: Rec f rs -> Rec f ss -> Rec f (rs ++ ss)
append = rappend

singleton :: f a -> Rec f '[a]
singleton v = v :& RNil

null :: Rec f rs -> Bool
null RNil = True
null (_ :& _) = False

foldl :: (forall a. b -> f a -> b) -> b -> Rec f rs -> b
foldl _ acc RNil = acc
foldl f acc (r :& rs) = foldl f (f acc r) rs

length :: Rec f rs -> Int
length = foldl (\i _ -> i + 1) 0

coapply :: Rec (Lift (->) f g) rs -> CoRec f rs -> CoRec g rs
coapply (Lift f :& rs) cr = case cr of
  CoRecHere v -> CoRecHere (f v)
  CoRecThere cr' -> CoRecThere (coapply rs cr')

replace :: CoRec f rs -> Rec f rs -> Rec f rs
replace (CoRecHere v) (_ :& rs) = v :& rs
replace (CoRecThere cr) (r :& rs) = r :& replace cr rs

modify :: CoRec Endo rs -> Rec Identity rs -> Rec Identity rs
modify (CoRecHere (Endo g)) (Identity r :& rs) = Identity (g r) :& rs
modify (CoRecThere cr) (r :& rs) = r :& modify cr rs

-- Requires that the list be infinite
fromList :: Rec proxy rs -> [a] -> Rec (Constant a) rs
fromList RNil _ = RNil
fromList (_ :& rs) (x : xs) = Constant x :& fromList rs xs

toList :: Rec (Constant a) rs -> [a]
toList RNil = []
toList (Constant a :& rs) = a : toList rs

toValue :: CoRec (Constant a) rs -> a
toValue (CoRecHere (Constant a)) = a
toValue (CoRecThere cr) = toValue cr

zip :: Rec f rs -> Rec g rs -> Rec (Product f g) rs
zip RNil RNil           = RNil
zip (a :& as) (b :& bs) = Pair a b :& zip as bs

unzip :: Rec (Product f g) rs -> (Rec f rs, Rec g rs)
unzip (Pair a b :& rs) = (a :& as, b :& bs)
  where (as, bs) = unzip rs

zip2 :: Rec f rs -> Rec g rs -> Rec (FunctorRec '[f,g]) rs
zip2 RNil RNil = RNil
zip2 (a :& as) (b :& bs) =
  FunctorRec (Flap a :& Flap b :& RNil) :& zip2 as bs

zip3 :: Rec f rs -> Rec g rs -> Rec h rs -> Rec (FunctorRec '[f,g,h]) rs
zip3 RNil RNil RNil = RNil
zip3 (a :& as) (b :& bs) (c :& cs) =
  FunctorRec (Flap a :& Flap b :& Flap c :& RNil) :& zip3 as bs cs

zip4 :: Rec f rs -> Rec g rs -> Rec h rs -> Rec k rs -> Rec (FunctorRec '[f,g,h,k]) rs
zip4 RNil RNil RNil RNil = RNil
zip4 (a :& as) (b :& bs) (c :& cs) (d :& ds) =
  FunctorRec (Flap a :& Flap b :& Flap c :& Flap d :& RNil) :& zip4 as bs cs ds

