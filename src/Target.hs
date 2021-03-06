{-# LANGUAGE DeriveGeneric, FlexibleInstances #-}
module Target (
    Target (..), PartialTarget (..), fromPartial, fullTarget, fullTargetWithWay
    ) where

import Base
import Builder
import GHC.Generics (Generic)
import Package
import Stage
import Way

-- Target captures all parameters relevant to the current build target:
-- * Stage and Package being built,
-- * Builder to be invoked,
-- * Way to be built (set to vanilla for most targets),
-- * source file(s) to be passed to Builder,
-- * file(s) to be produced.
data Target = Target
     {
        stage   :: Stage,
        package :: Package,
        builder :: Builder,
        way     :: Way,
        inputs  :: [FilePath],
        outputs :: [FilePath]
     }
     deriving (Show, Eq, Generic)

-- If values of type 'a' form a Monoid then we can also derive a Monoid instance
-- for values of type 'ReaderT Target Action a':
-- * the empty computation returns the identity element of the underlying type
-- * two computations can be combined by combining their results
instance Monoid a => Monoid (ReaderT Target Action a) where
    mempty  = return mempty
    mappend = liftM2 mappend

-- PartialTarget is a partially constructed Target with fields Stage and
-- Package only. PartialTarget's are used for generating build rules.
data PartialTarget = PartialTarget Stage Package deriving Show

-- Convert PartialTarget to Target assuming that unknown fields won't be used.
fromPartial :: PartialTarget -> Target
fromPartial (PartialTarget s p) = Target
    {
        stage   = s,
        package = p,
        builder = error "fromPartial: builder not set",
        way     = error "fromPartial: way not set",
        inputs  = error "fromPartial: inputs not set",
        outputs = error "fromPartial: outputs not set"
    }

-- Construct a full target by augmenting a PartialTarget with missing fields.
-- Most targets are built only one way, vanilla, hence we set it by default.
fullTarget :: PartialTarget -> Builder -> [FilePath] -> [FilePath] -> Target
fullTarget (PartialTarget s p) b srcs fs = Target
    {
        stage   = s,
        package = p,
        builder = b,
        way     = vanilla,
        inputs  = map unifyPath srcs,
        outputs = map unifyPath fs
    }

-- Use this function to be explicit about the build way.
fullTargetWithWay :: PartialTarget -> Builder -> Way -> [FilePath] -> [FilePath] -> Target
fullTargetWithWay pt b w srcs fs = (fullTarget pt b srcs fs) { way = w }

-- Instances for storing in the Shake database
instance Binary Target
instance NFData Target
instance Hashable Target
