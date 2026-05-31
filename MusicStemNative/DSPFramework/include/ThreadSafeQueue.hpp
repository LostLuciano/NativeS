#ifndef THREAD_SAFE_QUEUE_HPP
#define THREAD_SAFE_QUEUE_HPP

#include <queue>
#include <mutex>
#include <condition_variable>
#include <memory>

namespace DSP {

/// Thread-safe queue for inter-thread communication
template<typename T>
class ThreadSafeQueue {
public:
    // MARK: - Initialization
    
    ThreadSafeQueue() : closed(false) {}
    ~ThreadSafeQueue() = default;
    
    // Delete copy operations
    ThreadSafeQueue(const ThreadSafeQueue&) = delete;
    ThreadSafeQueue& operator=(const ThreadSafeQueue&) = delete;
    
    // MARK: - Operations
    
    /// Push item to queue
    void push(T item) {
        {
            std::lock_guard<std::mutex> lock(mutex);
            if (closed) {
                throw std::runtime_error("Queue is closed");
            }
            queue.push(std::move(item));
        }
        condition.notify_one();
    }
    
    /// Try to pop item (non-blocking)
    bool tryPop(T& item) {
        std::lock_guard<std::mutex> lock(mutex);
        if (queue.empty()) {
            return false;
        }
        item = std::move(queue.front());
        queue.pop();
        return true;
    }
    
    /// Pop item (blocking, waits for item or close)
    bool pop(T& item) {
        std::unique_lock<std::mutex> lock(mutex);
        condition.wait(lock, [this] { return !queue.empty() || closed; });
        
        if (queue.empty()) {
            return false;  // Queue is closed and empty
        }
        
        item = std::move(queue.front());
        queue.pop();
        return true;
    }
    
    /// Pop with timeout
    bool popWithTimeout(T& item, int timeoutMs) {
        std::unique_lock<std::mutex> lock(mutex);
        if (!condition.wait_for(lock, std::chrono::milliseconds(timeoutMs),
                               [this] { return !queue.empty() || closed; })) {
            return false;  // Timeout
        }
        
        if (queue.empty()) {
            return false;  // Queue is closed and empty
        }
        
        item = std::move(queue.front());
        queue.pop();
        return true;
    }
    
    /// Check if queue is empty
    bool isEmpty() const {
        std::lock_guard<std::mutex> lock(mutex);
        return queue.empty();
    }
    
    /// Get queue size
    size_t size() const {
        std::lock_guard<std::mutex> lock(mutex);
        return queue.size();
    }
    
    /// Close queue (no more items can be pushed)
    void close() {
        {
            std::lock_guard<std::mutex> lock(mutex);
            closed = true;
        }
        condition.notify_all();
    }
    
    /// Check if queue is closed
    bool isClosed() const {
        std::lock_guard<std::mutex> lock(mutex);
        return closed;
    }
    
    /// Clear all items
    void clear() {
        std::lock_guard<std::mutex> lock(mutex);
        while (!queue.empty()) {
            queue.pop();
        }
    }
    
private:
    mutable std::mutex mutex;
    std::condition_variable condition;
    std::queue<T> queue;
    bool closed;
};

} // namespace DSP

#endif // THREAD_SAFE_QUEUE_HPP
