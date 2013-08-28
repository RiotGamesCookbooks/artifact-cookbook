# All credit given to Activesupport
# https://github.com/rails/rails/blob/v3.2.13/activesupport/lib/active_support/core_ext/hash/diff.rb
class Hash
  def diff(h2)
    self.dup.delete_if { |k, v| h2[k] == v }.merge(h2.dup.delete_if { |k, v| self.has_key?(k) })
  end
end
