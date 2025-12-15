# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'cert-wallet' do
  # The dependency on SSL's static library keeps us from using CoreBitcoin as a Swift framework.
  # use_frameworks!

  # Pods for cert-wallet
  pod 'CoreBitcoin', :podspec => 'https://raw.github.com/oleganza/CoreBitcoin/master/CoreBitcoin.podspec', :inhibit_warnings => true

  target 'cert-walletTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'CoreBitcoin', :podspec => 'https://raw.github.com/oleganza/CoreBitcoin/master/CoreBitcoin.podspec', :inhibit_warnings => true
  end

  target 'cert-walletUITests' do
    inherit! :search_paths
    # Pods for testing
    pod 'CoreBitcoin', :podspec => 'https://raw.github.com/oleganza/CoreBitcoin/master/CoreBitcoin.podspec', :inhibit_warnings => true
  end

end
