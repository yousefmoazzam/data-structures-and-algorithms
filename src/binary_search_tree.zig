const std = @import("std");

const list = @import("linked_list.zig");
const stack = @import("stack.zig");

fn preorder(allocator: std.mem.Allocator, current_node: ?*Node, index_stack: *stack.Stack, visited_nodes: *list.SinglyLinkedList(*Node)) std.mem.Allocator.Error!void {
    const node = if (current_node) |val| val else {
        return;
    };

    try index_stack.*.push(allocator, node.*.value);

    // Visit the current node before traversing its left subtree
    try visited_nodes.*.append(allocator, node);

    // If the left child of the current node isn't null then traverse down the left subtree
    if (node.*.left) |left_child| {
        try preorder(allocator, left_child, index_stack, visited_nodes);
    }

    // After traversal of the current node's left subtree (or no traversal of the left subtree
    // at all if the left child was null), the current node's value must be popped off the
    // stack before traversing the right subtree
    if (index_stack.*.pop(allocator)) |_| {} else |_| {
        // If the algorithm is correct, an empty stack should never attempted to be popped.
        // Hence, unreachable.
        unreachable;
    }

    // If the right child is not null, then traverse the right subtree of the current node
    if (node.*.right) |right_child| {
        try preorder(allocator, right_child, index_stack, visited_nodes);
    }
}

/// Perform inorder traversal of binary tree via recursion
fn inorder(allocator: std.mem.Allocator, current_node: ?*Node, index_stack: *stack.Stack, visited_nodes: *list.SinglyLinkedList(*Node)) std.mem.Allocator.Error!void {
    const node = if (current_node) |val| val else {
        return;
    };

    try index_stack.*.push(allocator, node.*.value);

    // If the left child of current node is not null, keep traversing down the left subtree
    if (node.*.left) |left_child| {
        try inorder(allocator, left_child, index_stack, visited_nodes);
    }

    // If execution has reached here, then either the left child was null, or we have returned
    // from a recursive call that occurred in the above `if` statement.
    //
    // In either case, we must now pop off the current value and then note this index/node as
    // the next to be visited.
    if (index_stack.*.pop(allocator)) |_| {} else |_| {
        // If the algorithm is correct, an empty stack should never attempted to be popped.
        // Hence, unreachable.
        unreachable;
    }
    try visited_nodes.append(allocator, node);

    // Now need to explore right subtree, so check if the right child index is null or not, and
    // recurse down it if not
    if (node.*.right) |right_child| {
        try inorder(allocator, right_child, index_stack, visited_nodes);
    }
}

fn postorder(allocator: std.mem.Allocator, current_node: ?*Node, index_stack: *stack.Stack, visited_nodes: *list.SinglyLinkedList(*Node)) std.mem.Allocator.Error!void {
    const node = if (current_node) |val| val else {
        return;
    };

    try index_stack.*.push(allocator, node.*.value);

    // If the left child is not null, then traverse the left subtree
    if (node.*.left) |left_child| {
        try postorder(allocator, left_child, index_stack, visited_nodes);
    }

    // After traversing the left subtree (or not, if the left child was null), pop the value of
    // the current node off of the stack
    if (index_stack.*.pop(allocator)) |_| {} else |_| {
        // If the algorithm is correct, an empty stack should never attempted to be popped.
        // Hence, unreachable.
        unreachable;
    }

    // If the right child is not null, traverse the right subtree of the current node
    if (node.*.right) |right_child| {
        try postorder(allocator, right_child, index_stack, visited_nodes);
    }

    // Now that the right subtree has been traverse, visit the current node
    try visited_nodes.*.append(allocator, node);
}

fn recurse_right(node: *Node) *Node {
    if (node.*.right) |right_child| {
        return recurse_right(right_child);
    } else return node;
}

pub const PreorderTraversalEagerIterator = struct {
    nodes: *list.SinglyLinkedList(*Node),
    allocator: std.mem.Allocator,
    current: usize,

    pub fn next(self: *PreorderTraversalEagerIterator) ?u8 {
        if (self.current < self.nodes.*.len) {
            const val = if (self.nodes.get(self.current)) |node| node.*.value else |_| unreachable;
            self.current += 1;
            return val;
        }

        return null;
    }

    pub fn free(self: PreorderTraversalEagerIterator) void {
        self.nodes.*.free(self.allocator);
        self.allocator.destroy(self.nodes);
    }
};

/// Provides a slice of `u8` pointers in the order of traversal, where the traversal operations
/// have been eagerly evaluated to produce the slice
pub const InorderTraversalEagerIterator = struct {
    nodes: *list.SinglyLinkedList(*Node),
    allocator: std.mem.Allocator,
    current: usize,

    pub fn next(self: *InorderTraversalEagerIterator) ?u8 {
        if (self.current < self.nodes.*.len) {
            const val = if (self.nodes.get(self.current)) |node| node.*.value else |_| {
                // The `self.current` value starts at 0 and is incremented for each call to
                // `next()`. The `if` body only is executed if the `self.current` value is
                // within the bounds of the linked list, so
                // `SinglyLinkedList(Node).get(self.current)` should never return an
                // `OutOfBounds` error. Hence, unreachable.
                unreachable;
            };
            self.current += 1;
            return val;
        }

        return null;
    }

    /// Deallocate the linked list's elements, as well as the linked list struct value itself
    pub fn free(self: InorderTraversalEagerIterator) void {
        self.nodes.*.free(self.allocator);
        self.allocator.destroy(self.nodes);
    }
};

pub const PostorderTraversalEagerIterator = struct {
    nodes: *list.SinglyLinkedList(*Node),
    allocator: std.mem.Allocator,
    current: usize,

    pub fn next(self: *PostorderTraversalEagerIterator) ?u8 {
        if (self.current < self.nodes.*.len) {
            const val = if (self.nodes.get(self.current)) |node| node.*.value else |_| unreachable;
            self.current += 1;
            return val;
        }

        return null;
    }

    pub fn free(self: PostorderTraversalEagerIterator) void {
        self.nodes.*.free(self.allocator);
        self.allocator.destroy(self.nodes);
    }
};

const Error = error{
    EmptyTree,
    ElementNotFound,
};

const Node = struct {
    value: u8,
    left: ?*Node,
    right: ?*Node,
};

pub const BinarySearchTree = struct {
    allocator: std.mem.Allocator,
    root: ?*Node,

    pub fn new(allocator: std.mem.Allocator) std.mem.Allocator.Error!BinarySearchTree {
        return BinarySearchTree{ .allocator = allocator, .root = null };
    }

    pub fn insert(self: *BinarySearchTree, value: u8) std.mem.Allocator.Error!void {
        if (self.root == null) {
            const node = try self.allocator.create(Node);
            node.*.value = value;
            node.*.left = null;
            node.*.right = null;
            self.root = node;
            return;
        }

        // If execution has reached here, then the root node cannot be null, hence the
        // unwrapping of the optional `self.root` is safe to do
        try self.insert_recurse(self.root.?, value);
    }

    fn insert_recurse(self: *BinarySearchTree, node: *Node, value: u8) std.mem.Allocator.Error!void {
        const is_value_less_than_current = value < node.*.value;
        if (is_value_less_than_current) {
            if (node.*.left) |left_child| {
                // Carry on recursing down left subtree
                return try self.insert_recurse(left_child, value);
            } else {
                // Value to insert is smaller than value in current node, but the left child is
                // a null node, so set the current node's left child to a new node containing
                // the value to insert.
                const new_node = try self.allocator.create(Node);
                new_node.*.value = value;
                new_node.*.left = null;
                new_node.*.right = null;
                node.*.left = new_node;
                return;
            }
        }

        // If execution has reached here, then the value is >= to the current value.
        //
        // NOTE: Not handling duplicate values for now, so assume value is > current value, so
        // need to recurse down right subtree.
        if (node.*.right) |right_child| {
            return try self.insert_recurse(right_child, value);
        } else {
            // The right child of the current node is null, so set the current node's right
            // child to a new node containing the value to insert.
            const new_node = try self.allocator.create(Node);
            new_node.*.value = value;
            new_node.*.left = null;
            new_node.*.right = null;
            node.*.right = new_node;
            return;
        }
    }

    pub fn remove(self: *BinarySearchTree, value: u8) Error!void {
        if (self.root == null) {
            return Error.EmptyTree;
        }
        self.root = try self.remove_recurse(self.root, value);
    }

    fn remove_recurse(self: *BinarySearchTree, node: ?*Node, value: u8) Error!?*Node {
        const current_node = if (node) |val| val else {
            // The BST cannot be empty, because a `EmptyTree` error would have been returned in
            // `remove()`. This means that recursion down the tree in an attempt to find the
            // value to remove in the tree has resulted in hitting a null node. This means that
            // the value isn't in the BST, so return an error.
            return Error.ElementNotFound;
        };

        if (value < current_node.*.value) {
            // The left subtree of the current node contains the node to remove. Reassign the
            // left child of the current node to the returned node of the next layer of
            // recursion:
            // - if the next layer contains the node to remove, then the return value will be
            // the successor node of the removed node
            // - if the next layer doesn't contain the node to remove, the return value will be
            // the same left child node (ie, the left child will be reassigned, but to the same
            // node as it was before); this is what the return statement at the very end of the
            // function body takes care of
            current_node.*.left = try self.remove_recurse(current_node.*.left, value);
        } else if (value > current_node.*.value) {
            // The right subtree of the current node contains the node to remove. Reassign the
            // right child of the current node to the returned node of the next layer of
            // recursion.
            //
            // The two possibilities of what can be returned for the next recursive call are
            // the same as detailed in the left child case above, but for the right child.
            current_node.*.right = try self.remove_recurse(current_node.*.right, value);
        } else {
            // Node value is equal to the given value, so this is the node to remove. Need to
            // check if there are:
            // - no children
            // - only left subtree and no right subtree
            // - only right subtree and no left subtree
            //
            // to handle the BST in the aftermath of the removal, to ensure that the BST
            // invariant is still held.

            if (current_node.*.left == null and current_node.*.right == null) {
                self.allocator.destroy(current_node);
                return null;
            }

            if (current_node.*.right == null) {
                const left_child = current_node.*.left;
                self.allocator.destroy(current_node);
                return left_child;
            }

            if (current_node.*.left == null) {
                const right_child = current_node.*.right;
                self.allocator.destroy(current_node);
                return right_child;
            }

            // If execution has reached this far, then the node to remove has two child nodes,
            // so a successor node must be chosen from one of the two subtrees to be the
            // replacement of the node to remove that *also* enables the BST invariant to still
            // be held.
            //
            // Two choices:
            // - largest value in left subtree
            // - smallest value in right subtree
            //
            // Arbitrarily, pick largest value in left subtree. So, this needs to be found
            // before the swap can occur.
            const largest_in_left_subtree = recurse_right(current_node.*.left.?);
            const value_to_swap_with = largest_in_left_subtree.*.value;

            // Before replacing the value in the node we want to remove with the value in the
            // successor, we must first remove the successor node (to get rid of the duplicate
            // value that would exist after the replacement is done).
            //
            // NOTE: The replacement cannot be done before this, because otherwise the removal
            // will attempt to remove the current node rather than the successor.
            //
            // Bear in mind that the node we "remove" is strictly speaking not the node that
            // contained the value we wanted to remove - instead, the node with the value we
            // want to remove has its value replaced to main the BST invariant, and the node
            // actually removed is the node that is the successor.
            self.root = if (self.remove_recurse(self.root, largest_in_left_subtree.*.value)) |val| val else |_| {
                // Recursion to find the node to remove has already found the node to remove,
                // and a successor has been found as well. This must mean that the value
                // requested to be removed exists in the BST, so an `ElementNotFound` error
                // shouldn't be encountered. Hence, unreachable.
                unreachable;
            };

            // Finally, swap the value in the node to remove, with the largest value in the
            // left subtree
            current_node.*.value = value_to_swap_with;
        }

        // This takes care of layers in the recursion where the node to remove wasn't found,
        // and the same child node needed to be returned (rather than reassigning the child to
        // another node - namely, to a different successor node, in the event when a node is
        // removed and a successor needs to be returned instead, which is what the `else`
        // branch above is doing).
        return current_node;
    }

    pub fn preorderTraversal(self: BinarySearchTree) std.mem.Allocator.Error!PreorderTraversalEagerIterator {
        const index_stack = try self.allocator.create(stack.Stack);
        index_stack.* = stack.Stack.new();
        const visited_nodes = try self.allocator.create(list.SinglyLinkedList(*Node));
        visited_nodes.* = list.SinglyLinkedList(*Node).new();

        // Traverse BST
        try preorder(self.allocator, self.root, index_stack, visited_nodes);

        // Deallocate memory for stack used in traversal
        index_stack.*.free(self.allocator);
        self.allocator.destroy(index_stack);

        return PreorderTraversalEagerIterator{
            .nodes = visited_nodes,
            .allocator = self.allocator,
            .current = 0,
        };
    }

    pub fn inorderTraversal(self: BinarySearchTree) std.mem.Allocator.Error!InorderTraversalEagerIterator {
        const nodes = try self.getListOfNodePtrs();
        return InorderTraversalEagerIterator{
            .nodes = nodes,
            .allocator = self.allocator,
            .current = 0,
        };
    }

    pub fn postorderTraversal(self: BinarySearchTree) std.mem.Allocator.Error!PostorderTraversalEagerIterator {
        const index_stack = try self.allocator.create(stack.Stack);
        index_stack.* = stack.Stack.new();
        const visited_nodes = try self.allocator.create(list.SinglyLinkedList(*Node));
        visited_nodes.* = list.SinglyLinkedList(*Node).new();

        // Traverse BST
        try postorder(self.allocator, self.root, index_stack, visited_nodes);

        // Deallocate memory for stack used in traversal
        index_stack.*.free(self.allocator);
        self.allocator.destroy(index_stack);

        return PostorderTraversalEagerIterator{
            .nodes = visited_nodes,
            .allocator = self.allocator,
            .current = 0,
        };
    }

    fn getListOfNodePtrs(self: BinarySearchTree) std.mem.Allocator.Error!*list.SinglyLinkedList(*Node) {
        const index_stack = try self.allocator.create(stack.Stack);
        index_stack.* = stack.Stack.new();
        const visited_nodes = try self.allocator.create(list.SinglyLinkedList(*Node));
        visited_nodes.* = list.SinglyLinkedList(*Node).new();

        // Traverse BST
        try inorder(self.allocator, self.root, index_stack, visited_nodes);

        // Deallocate memory for stack used in traversal
        index_stack.*.free(self.allocator);
        self.allocator.destroy(index_stack);

        return visited_nodes;
    }

    pub fn free(self: *BinarySearchTree) std.mem.Allocator.Error!void {
        const bst_node_ptrs_list = try self.getListOfNodePtrs();

        // `traversal_ptr` is a pointer to a `Node` in a singly linked list, which in turn has
        // a value which is a pointer to a BST `Node`
        //
        // Meaning, to get to a pointer to a BST `Node`, we must:
        // - unwrap the optional pointer to a singly linked list node (to get a pointer to a
        // singly linked list node)
        // - dereference the pointer to a singly linked list node (to get a pointer to a BST
        // node)
        var traversal_ptr = bst_node_ptrs_list.head;
        var count: usize = 0;
        while (traversal_ptr != null) : (count += 1) {
            // `traversal_ptr` has been confirmed to not be null, so the unwrap is safe to do.
            self.allocator.destroy(traversal_ptr.?.*.value);
            traversal_ptr = traversal_ptr.?.next;
        }

        // Deallocate the linked list of BST node pointers
        bst_node_ptrs_list.*.free(self.allocator);
        self.allocator.destroy(bst_node_ptrs_list);
    }
};

test "inorder traversal iterator produces correct ordering of visited nodes" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 };
    const expected_ordering = values;

    // Insert values into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get eagerly evaluated iterator over BST for performing inorder traversal
    var iterator = try bst.inorderTraversal();

    // Traverse iterator and check each element is as expected, based on the assumption of the
    // array representation of a binary tree's nodes
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(expected_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "inorder traversal over BST with null nodes produces correct ordering of visited nodes" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 7, 5, 20, 4, 6, 15, 33, 2, 10, 25 };
    const expected_ordering = [_]u8{ 2, 4, 5, 6, 7, 10, 15, 20, 25, 33 };

    // Insert values into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get inorder traversal iterator over BST
    var iterator = try bst.inorderTraversal();

    // Traverse iterator and check each element is as expected
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(expected_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "inserting elements into binary search tree produces correct ordering" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 7, 1, 3, 9, 14, 4, 19, 18, 10, 2, 31, 16, 5, 29, 11 };
    const inorder_ordering = [_]u8{ 1, 2, 3, 4, 5, 7, 9, 10, 11, 14, 16, 18, 19, 29, 31 };

    // Insert values into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get eagerly evaluated iterator over BST for performing inorder traversal
    var iterator = try bst.inorderTraversal();

    // Traverse inorder iterator and check the values are in the expected ordering
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(inorder_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "empty BST produces inorder iterator of length 0" {
    const allocator = std.testing.allocator;
    const bst = try BinarySearchTree.new(allocator);
    const iterator = try bst.inorderTraversal();
    try std.testing.expectEqual(0, iterator.nodes.len);
    iterator.free();
}

test "remove root node in BST with only one node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const value = 5;
    try bst.insert(value);
    try bst.remove(value);

    // Get inorder iterator over BST and check its length is zero
    const iterator = try bst.inorderTraversal();
    try std.testing.expectEqual(0, iterator.nodes.len);

    // Free iterator
    iterator.free();
}

test "remove root node in BST with single subtree (left) of root node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 2, 1 };
    const value_to_remove = 2;
    const value_to_keep = 1;

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Remove root value
    try bst.remove(value_to_remove);

    // Get inorder iterator over BST
    var iterator = try bst.inorderTraversal();

    // Check iterator's length is one
    try std.testing.expectEqual(1, iterator.nodes.len);

    // Check single value in iterator is as expected
    try std.testing.expectEqual(value_to_keep, iterator.next());

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "remove root node in BST with single subtree (right) of root node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 1, 2 };
    const value_to_remove = 1;
    const value_to_keep = 2;

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Remove root value
    try bst.remove(value_to_remove);

    // Get inorder iterator over BST
    var iterator = try bst.inorderTraversal();

    // Check iterator's length is one
    try std.testing.expectEqual(1, iterator.nodes.len);

    // Check single value in iterator is as expected
    try std.testing.expectEqual(value_to_keep, iterator.next());

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "remove leaf node at top of left subtree of root node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 2, 1, 3 };
    const value_to_remove = 1;
    const values_to_keep = [_]u8{ 2, 3 };

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Remove element which is a leaf node in the BST
    try bst.remove(value_to_remove);

    // Get inorder iterator over BST
    var iterator = try bst.inorderTraversal();

    // Check iterator's length is as expected
    try std.testing.expectEqual(values_to_keep.len, iterator.nodes.len);

    // Check values in the iterator are as expected
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(values_to_keep[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "remove leaf node at top of right subtree of root node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 2, 1, 3 };
    const value_to_remove = 3;
    const values_to_keep = [_]u8{ 1, 2 };

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Remove element which is a leaf node in the BST
    try bst.remove(value_to_remove);

    // Get inorder iterator over BST
    var iterator = try bst.inorderTraversal();

    // Check iterator's length is as expected
    try std.testing.expectEqual(values_to_keep.len, iterator.nodes.len);

    // Check values in the iterator are as expected
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(values_to_keep[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "remove root node in BST with two subtrees of root node" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 6, 3, 8 };
    const value_to_remove = 6;
    const values_to_keep = [_]u8{ 3, 8 };

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Remove root value
    try bst.remove(value_to_remove);

    // Get inorder iterator over BST
    var iterator = try bst.inorderTraversal();

    // Check iterator's length is as expected
    try std.testing.expectEqual(values_to_keep.len, iterator.nodes.len);

    // Check values in iterator are as expected
    for (values_to_keep) |value| {
        try std.testing.expectEqual(value, iterator.next());
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "return error if removing element from empty BST" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const res = bst.remove(3);
    try std.testing.expectError(Error.EmptyTree, res);
}

test "return error if removing value from BST that doesn't exist in it" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 6, 3, 8 };
    const non_existent_value = 4;

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Attempt to remove non-existent value in BST, and check that an error is returned
    const res = bst.remove(non_existent_value);
    try std.testing.expectError(Error.ElementNotFound, res);

    // Free BST
    try bst.free();
}

test "preorder traversal iterator produces correct ordering of visited nodes" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 7, 1, 3, 9, 14, 4, 19, 18, 10, 2, 31, 16, 5, 29, 11 };
    const expected_ordering = [_]u8{ 7, 1, 3, 2, 4, 5, 9, 14, 10, 11, 19, 18, 16, 31, 29 };

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get preorder traversal iterator over BST
    var iterator = try bst.preorderTraversal();

    // Traverse preorder iterator and check the visited nodes ordering is as expected
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(expected_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}

test "postorder traversal iterator produces correct ordering of visited nodes" {
    const allocator = std.testing.allocator;
    var bst = try BinarySearchTree.new(allocator);
    const values = [_]u8{ 7, 1, 3, 9, 14, 4, 19, 18, 10, 2, 31, 16, 5, 29, 11 };
    const expected_ordering = [_]u8{ 2, 5, 4, 3, 1, 11, 10, 16, 18, 29, 31, 19, 14, 9, 7 };

    // Insert elements into BST
    for (values) |value| {
        try bst.insert(value);
    }

    // Get postorder traversal iterator over BST
    var iterator = try bst.postorderTraversal();

    // Traverse postorder iterator and check the visited nodes ordering is as expected
    var count: usize = 0;
    while (iterator.next()) |item| {
        try std.testing.expectEqual(expected_ordering[count], item);
        count += 1;
    }

    // Free iterator and BST
    iterator.free();
    try bst.free();
}
