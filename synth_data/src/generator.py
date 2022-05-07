import datetime, math, logging, random, sys, time
import argparse, csv
from faker import Faker

fake = Faker('en_US')
Faker.seed(time.time_ns())

def generate_customer_record(): 
  # Customer data file layout: 
  # Cust_Id, First_Name, Last_Name, SSN, DOB, Nationality, Email_Address, Primary_Phone, Address_Line1, Address_Line2, City, State_Code, Postal_Code
  cust = {}
  cust['Cust_Id'] = fake.unique.random_number(digits=10, fix_len=True)
  cust['First_Name'] = fake.first_name()
  cust['Last_Name'] = fake.last_name()
  cust['SSN'] = fake.ssn()
  cust['DOB'] = fake.date_of_birth(minimum_age = 18)
  cust['Nationality'] = 'USA' if random.random() < 0.80 else fake.country_code(representation='alpha-3')
  cust['Email_Address'] = fake.ascii_email()
  cust['Primary_Phone'] = fake.phone_number()
  cust['Address_Line1'] = fake.street_address()
  cust['Address_Line2'] = fake.secondary_address() if random.random() < 0.2 else ''
  cust['City'] = fake.city()
  cust['State_Code'] = fake.state_abbr()
  cust['Postal_Code'] = fake.postalcode()
  return cust

def generate_account_record(cust_id): 
  # Account data file layout: 
  # Account_Id, Cust_Id, Account_Type, Status, Date_Opened, Current_Balance, Available_Balance
  account = {}
  account['Account_Id'] = fake.unique.random_number(digits=9, fix_len=True)
  account['Cust_Id'] = cust_id 
  account['Account_Type'] = random.choice(['CKG', 'CKG', 'CKG', 'SAV', 'SAV', 'IRA']) 
  account['Status'] = random.choice(['A', 'A', 'A', 'A', 'C', 'S'])
  account['Date_Opened'] = fake.date_between_dates(date_start = datetime.datetime(1930, 1, 1)) 
  account['Current_Balance'] = round(random.uniform(0, 9999.99), 2) 
  account['Available_Balance'] = round(account['Current_Balance'] - (0 if random.random() < 0.40 else random.uniform(0, 199.99)), 2)
  return account


def main(): 

  cliparser = argparse.ArgumentParser(
    description = 'generates large amounts of data and writes to a file', 
  )
  cliparser.add_argument('--debug', 
    required=False, 
    action='store_true', 
    default=False, 
    help='enables debug logging mode'
  )
  cliparser.add_argument('--records', 
    required=False, 
    type=int, 
    default=100, 
    help='number of records of data to generate'
  )
  cliparser.add_argument('--customer-file', 
    required=False, 
    default='customer_data.csv', 
    help='customer output file name'
  )
  cliparser.add_argument('--account-file', 
    required=False, 
    default='account_data.csv', 
    help='account output file name'
  )

  # extract cli option values and set program behavior
  args = cliparser.parse_args()

  # configure logger
  log_level = logging.DEBUG if args.debug else logging.INFO
  root = logging.getLogger()
  if root.handlers:
      for handler in root.handlers:
          root.removeHandler(handler)
  logging.basicConfig(format='%(asctime)s - %(levelname)s - %(message)s', level = log_level)

  CUSTOMER_RECORD_COUNT = args.records
  CUSTOMER_FILE_NAME = args.customer_file
  ACCOUNT_FILE_NAME = args.account_file

  toolbar_width = 100

  try: 
    # setup toolbar
    sys.stdout.write("[%s]" % (" " * toolbar_width))
    sys.stdout.flush()
    sys.stdout.write("\b" * (toolbar_width+1)) # return to start of line, after '['
    toolbar_progress = 0

    customer = generate_customer_record()
    account = generate_account_record(customer['Cust_Id'])

    cust_file = open(CUSTOMER_FILE_NAME, 'w', newline='')
    cust_file_writer = csv.DictWriter(cust_file, customer.keys())
    cust_file_writer.writeheader()
    cust_file_writer.writerow(customer)

    acct_file = open(ACCOUNT_FILE_NAME, 'w', newline='')
    acct_file_writer = csv.DictWriter(acct_file, account.keys())
    acct_file_writer.writeheader()
    acct_file_writer.writerow(account)

    for _i in range(CUSTOMER_RECORD_COUNT - 1): 
      customer = generate_customer_record()
      cust_file_writer.writerow(customer)

      account = generate_account_record(customer['Cust_Id'])
      acct_file_writer.writerow(account)

      if math.floor(_i * toolbar_width / CUSTOMER_RECORD_COUNT) >= toolbar_progress: 
        toolbar_progress += 1
        sys.stdout.write("-")
        sys.stdout.flush()

  finally: 
    cust_file.close()
    acct_file.close()
    sys.stdout.write("\n")

if __name__ == '__main__':
  main()