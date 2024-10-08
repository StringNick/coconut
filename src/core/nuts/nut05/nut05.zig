//! NUT-05: Melting Tokens
//!
//! <https://github.com/cashubtc/nuts/blob/main/05.md>
const BlindSignature = @import("../nut00/lib.zig").BlindSignature;
const BlindedMessage = @import("../nut00/lib.zig").BlindedMessage;
const CurrencyUnit = @import("../nut00/lib.zig").CurrencyUnit;
const Proof = @import("../nut00/lib.zig").Proof;
const PaymentMethod = @import("../nut00/lib.zig").PaymentMethod;
const Mpp = @import("../nut15/nut15.zig").Mpp;
const Bolt11Invoice = @import("../../../mint/lightning/invoices/lib.zig").Bolt11Invoice;
const std = @import("std");

/// Melt quote request [NUT-05]
pub const MeltQuoteBolt11Request = struct {
    /// Bolt11 invoice to be paid
    request: Bolt11Invoice,
    /// Unit wallet would like to pay with
    unit: CurrencyUnit,
    /// Payment Options
    options: ?Mpp = null,
};

pub const QuoteState = enum {
    /// Quote has not been paid
    unpaid,
    /// Quote has been paid
    paid,
    /// Paying quote is in progress
    pending,

    pub fn toString(self: QuoteState) []const u8 {
        return switch (self) {
            .unpaid => "UNPAID",
            .paid => "PAID",
            .pending => "PENDING",
        };
    }

    pub fn fromString(s: []const u8) !QuoteState {
        const kv = std.StaticStringMap(QuoteState).initComptime(
            &.{
                .{ "UNPAID", QuoteState.unpaid },
                .{ "PAID", QuoteState.paid },
                .{ "PENDING", QuoteState.pending },
            },
        );

        return kv.get(s) orelse return error.UnknownState;
    }
};

/// Melt quote response [NUT-05]
pub const MeltQuoteBolt11Response = struct {
    /// Quote Id
    quote: []const u8,
    /// The amount that needs to be provided
    amount: u64,
    /// The fee reserve that is required
    fee_reserve: u64,
    /// Whether the the request haas be paid
    // TODO: To be deprecated
    /// Deprecated
    paid: ?bool,
    /// Quote State
    state: QuoteState,
    /// Unix timestamp until the quote is valid
    expiry: u64,
    /// Payment preimage
    payment_preimage: ?[]const u8 = null,
    /// Change
    change: ?[]const BlindSignature = null,
};

/// Melt Bolt11 Request [NUT-05]
pub const MeltBolt11Request = struct {
    /// Quote ID
    quote: []const u8,
    /// Proofs
    inputs: []const Proof,
    /// Blinded Message that can be used to return change [NUT-08]
    /// Amount field of BlindedMessages `SHOULD` be set to zero
    outputs: ?[]const BlindedMessage = null,

    /// Total [`Amount`] of [`Proofs`]
    pub fn proofsAmount(self: MeltBolt11Request) u64 {
        var sum: u64 = 0;
        for (self.inputs) |proof| {
            sum += proof.amount;
        }

        return sum;
    }
};

// TODO: to be deprecated
/// Melt Response [NUT-05]
pub const MeltBolt11Response = struct {
    /// Indicate if payment was successful
    paid: bool,
    /// Bolt11 preimage
    payment_preimage: ?[]const u8 = null,
    /// Change
    change: ?[]const BlindSignature,
    // impl From<MeltQuoteBolt11Response> for MeltBolt11Response {
};

/// Melt Method Settings
pub const MeltMethodSettings = struct {
    /// Payment Method e.g. bolt11
    method: PaymentMethod,
    /// Currency Unit e.g. sat
    unit: CurrencyUnit = .sat,
    /// Min Amount
    min_amount: ?u64 = null,
    /// Max Amount
    max_amount: ?u64 = null,
};

/// Melt Settings
pub const Settings = struct {
    /// Methods to melt
    methods: []const MeltMethodSettings = &.{
        .{
            .method = .bolt11,
            .unit = .sat,
            .min_amount = 1,
            .max_amount = 1000000,
        },
    },
    /// Minting disabled
    disabled: bool = false,

    // /// Get [`MeltMethodSettings`] for unit method pair
    // pub fn get_settings(
    //     &self,
    //     unit: &CurrencyUnit,
    //     method: &PaymentMethod,
    // ) -> Option<MeltMethodSettings> {
    //     for method_settings in self.methods.iter() {
    //         if method_settings.method.eq(method) && method_settings.unit.eq(unit) {
    //             return Some(method_settings.clone());
    //         }
    //     }

    //     None
    // }
};
