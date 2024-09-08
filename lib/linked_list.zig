const std = @import("std");

const SinglyLinkedList = struct {
    const Node = struct {
        value: u8,
        next: ?*Node,
    };

    len: usize,
    head: ?*Node,
    tail: ?*Node,

    fn new() SinglyLinkedList {
        return SinglyLinkedList{
            .len = 0,
            .head = null,
            .tail = null,
        };
    }

    fn free(self: *SinglyLinkedList, allocator: std.mem.Allocator) std.mem.Allocator.Error!void {
        // Zero elements in the linked list
        if (self.len == 0) {
            return;
        }

        // One or more elements in the linked list
        var next = self.head.?.next;
        while (next != null) {
            allocator.destroy(self.head.?);
            self.head = next;
            next = self.head.?.next;
        }
        allocator.destroy(self.head.?);
        self.len = 0;
    }

    fn get(self: SinglyLinkedList, idx: usize) u8 {
        var node = self.head;
        var i: usize = 0;
        while (i < idx) : (i += 1) {
            node = node.?.next;
        }
        return node.?.value;
    }

    fn append(self: *SinglyLinkedList, allocator: std.mem.Allocator, value: u8) std.mem.Allocator.Error!void {
        var node = try allocator.create(Node);
        node.value = value;
        node.next = null;

        if (self.len == 0) {
            self.head = node;
        } else {
            self.tail.?.next = node;
        }

        self.tail = node;
        self.len += 1;
    }
};

test "create singly linked list" {
    const list = SinglyLinkedList.new();
    try std.testing.expectEqual(0, list.len);
}

test "append elements to singly linked list" {
    var list = SinglyLinkedList.new();
    const valuesToAppend = [_]u8{ 4, 5, 6 };
    const allocator = std.testing.allocator;

    // Append values to list
    for (valuesToAppend) |value| {
        try list.append(allocator, value);
    }

    // Verify that the list is the expected length
    try std.testing.expectEqual(valuesToAppend.len, list.len);

    // Verify that the list contains the expected elements
    for (0..valuesToAppend.len) |i| {
        try std.testing.expectEqual(valuesToAppend[i], list.get(i));
    }

    // Free linked list
    try list.free(allocator);
}

test "free multi-element singly linked list" {
    var list = SinglyLinkedList.new();
    const valuesToAppend = [_]u8{ 1, 2 };
    const allocator = std.testing.allocator;

    // Append values to list
    for (valuesToAppend) |value| {
        try list.append(allocator, value);
    }

    // Free linked list and check that it is empty
    try list.free(allocator);
    try std.testing.expectEqual(0, list.len);
}
