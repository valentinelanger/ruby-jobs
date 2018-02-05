require 'json'

data = JSON.parse(File.read('data.json'))
workers = data['workers']
shifts = data['shifts']
PRICES = {'medic' =>  270, 'interne' => 126, 'interim' => 480}
COMMISSION = 0.05
FIXED_FEE_INTERIM = 80

def count_shift_per_worker(shifts, worker_id)
    shifts.count do |shift|
        shift['user_id'] == worker_id
    end
end

def count_interim_shifts(workers, shifts)
    interim_workers = workers.select { |worker| worker['status'] == 'interim' }
    nb_interim_shift = 0
    interim_workers.each do |interim|
        nb_interim_shift += shifts.count { |shift| shift['user_id'] == interim['id'] }
    end
    nb_interim_shift
end

def get_shift_per_worker(shifts, worker_id)
    shifts.select { |shift| shift['user_id'] == worker_id }
end

def get_date_coefficient(date)
    array_date = date.split('-')
    time = Time.new(array_date[0], array_date[1], array_date[2])
    time.saturday? || time.sunday? ? 2 : 1
end

def calculate_wage_per_worker(worker_shifts, worker)
    sum = 0
    worker_shifts.each do |shift|
        sum += get_date_coefficient(shift['start_date']) * PRICES[worker['status']]
    end
    sum
end

def caculate_fee_per_worker(worker_shifts, worker)
    fee_sum = 0
    if worker['status'] == 'interim'
        fee_sum += FIXED_FEE_INTERIM * worker_shifts.count
    end
    worker_shifts.each do |shift|
        fee_sum += get_date_coefficient(shift['start_date']) * PRICES[worker['status']] * COMMISSION
    end
    fee_sum
end

def calculate_wages(workers, shifts)
    workers.each do |worker|
        shift_worker = get_shift_per_worker(shifts, worker['id'])
        worker['price'] = calculate_wage_per_worker(shift_worker, worker)
    end
end

def calculate_total_fees(workers, shifts)
    total_fee = 0
    workers.each do |worker|
        shift_worker = get_shift_per_worker(shifts, worker['id'])
        total_fee += caculate_fee_per_worker(shift_worker, worker)
    end
    total_fee
end

def build_worker_list(workers)
    workers.each do |worker|
        worker.select! { |k,v| k == 'id' || k == 'price' }
    end
    return { 'workers' => workers }
end

def build_list(workers, shifts)
    pdg_fee = calculate_total_fees(workers, shifts)
    interim_shifts = count_interim_shifts(workers, shifts)
    workers = build_worker_list(workers)
    workers.merge({'commissions' => { 'pdg_fee' => pdg_fee, 'interim_shifts' => interim_shifts }})
end

def store_price_per_user(workers)
    File.open('output_vl.json', 'wb') do |file|
      file.write(JSON.pretty_generate(workers))
    end
end

store_price_per_user(build_list(calculate_wages(workers, shifts), shifts))
