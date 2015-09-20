module Settings.Builders.Alex (alexArgs) where

import Expression
import GHC (compiler)
import Predicates (builder, package)

alexArgs :: Args
alexArgs = builder Alex ? do
    file <- getFile
    src  <- getSource
    mconcat [ arg "-g"
            , package compiler ? arg "--latin1"
            , arg src
            , arg "-o", arg file ]